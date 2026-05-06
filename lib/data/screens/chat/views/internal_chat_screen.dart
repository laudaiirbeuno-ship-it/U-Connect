import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/utils/user_permissions.dart';
import 'package:uconnect/data/services/internal_chat_service.dart';
import 'package:uconnect/data/services/chat_polling_service.dart';
import 'package:uconnect/data/services/typing_indicator_service.dart';
import 'package:uconnect/data/services/chat_notification_service.dart';
import 'package:uconnect/data/model/internal_chat_message.dart';
import 'package:uconnect/data/screens/chat/widgets/chat_message_bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:uconnect/data/services/chat_offline_service.dart';
import 'package:record/record.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class InternalChatScreen extends StatefulWidget {
  final int receiverId;

  const InternalChatScreen({
    Key? key,
    required this.receiverId,
  }) : super(key: key);

  @override
  State<InternalChatScreen> createState() => _InternalChatScreenState();
}

class _InternalChatScreenState extends State<InternalChatScreen> {
  final InternalChatService _chatService = InternalChatService();
  final ChatPollingService _pollingService = ChatPollingService(InternalChatService());
  TypingIndicator? _typingIndicator;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<InternalChatMessage> _messages = [];
  Map<String, dynamic> _userSettings = {};
  int? _currentUserId;
  Map<int, Map<String, String>> _userProfiles = {}; // senderId -> {name, avatar}
  bool _loading = true;
  bool _sending = false;
  List<int> _typingUsers = [];
  InternalChatMessage? _replyingTo;
  List<Map<String, dynamic>> _devices = [];
  bool _loadingDevices = false;
  bool _isAdminOrManager = false;
  
  // Funcionalidades adicionais
  String _searchQuery = '';
  bool _isSearching = false;
  AudioPlayer? _audioPlayer;
  bool _isPlayingAudio = false;
  String? _currentAudioUrl;
  int? _editingMessageId;
  TextEditingController? _editController;
  
  // Paginação
  bool _hasMoreMessages = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  
  // Offline
  final ChatOfflineService _offlineService = ChatOfflineService();
  bool _isOnline = true;
  List<Map<String, dynamic>> _pendingMessages = [];
  
  // Áudio
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    // Marcar chat como aberto para parar notificações
    ChatNotificationService().markChatAsOpen();
    _checkPermissions();
    _initializeOfflineSupport();
    _loadMessages();
    _startPolling();
    _typingIndicator = TypingIndicator(_chatService, widget.receiverId);
    
    _messageController.addListener(() {
      _typingIndicator?.onTextChanged();
    });
  }

  Future<void> _initializeOfflineSupport() async {
    // Verificar conectividade inicial
    _isOnline = await _offlineService.isOnline();
    
    // Configurar listener de conectividade
    _offlineService.initializeConnectivityListener((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
      
      if (isOnline) {
        // Sincronizar mensagens pendentes quando voltar online
        _syncPendingMessages();
        // Recarregar mensagens do servidor
        _loadMessages();
      }
    });
    
    // Carregar mensagens pendentes
    _pendingMessages = await _offlineService.loadPendingMessages(widget.receiverId);
  }

  Future<void> _checkPermissions() async {
    final isAdminOrManager = await UserPermissions.isAdminOrManager();
    setState(() {
      _isAdminOrManager = isAdminOrManager;
    });
  }

  @override
  void dispose() {
    // Marcar chat como fechado
    ChatNotificationService().markChatAsClosed();
    _pollingService.stopPolling();
    _typingIndicator?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    // Verificar conectividade
    _isOnline = await _offlineService.isOnline();
    
    setState(() => _loading = true);

    try {
      if (_isOnline) {
        // Tentar carregar do servidor
        final response = await _chatService.getMessages(widget.receiverId);
        setState(() {
          _messages = response.messages;
          _userSettings = response.user;
          _currentUserId = response.user['id'];
          _loading = false;
        });
        
        // Salvar no cache
        await _offlineService.saveMessages(widget.receiverId, _messages);
        
        _scrollToBottom();
      } else {
        // Carregar do cache offline
        final cachedMessages = await _offlineService.loadCachedMessages(widget.receiverId);
        setState(() {
          _messages = cachedMessages;
          _loading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(
                context,
                'Modo offline - Mensagens do cache',
                'Offline mode - Cached messages',
              )),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Se falhar, tentar carregar do cache
      try {
        final cachedMessages = await _offlineService.loadCachedMessages(widget.receiverId);
        setState(() {
          _messages = cachedMessages;
          _loading = false;
          _isOnline = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(
                context,
                'Sem conexão - Exibindo mensagens do cache',
                'No connection - Showing cached messages',
              )),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (cacheError) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar mensagens: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _startPolling() {
    _pollingService.startPolling(receiverId: widget.receiverId);
    _pollingService.onNewMessages((messages) {
      setState(() {
        // Adicionar apenas mensagens novas (que não estão na lista)
        for (var msg in messages) {
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
          }
        }
        // Ordenar por data
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });
      _scrollToBottom();
    });
    _pollingService.onTyping((userIds) {
      setState(() {
        _typingUsers = userIds;
      });
    });
  }

  Future<void> _sendMessage({File? file, int? replyToId}) async {
    final message = _messageController.text.trim();
    if (message.isEmpty && file == null) return;

    setState(() => _sending = true);

    // Verificar conectividade
    _isOnline = await _offlineService.isOnline();

    if (!_isOnline) {
      // Modo offline - salvar mensagem pendente
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final pendingMessage = {
        'temp_id': tempId,
        'receiver_id': widget.receiverId,
        'message': message,
        'reply_to_id': replyToId ?? _replyingTo?.id,
        'file_path': file?.path,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _offlineService.savePendingMessage(widget.receiverId, pendingMessage);
      
      // Adicionar mensagem localmente para exibição imediata
      final localMessage = InternalChatMessage(
        id: -int.parse(tempId), // ID negativo para identificar como pendente
        senderId: _currentUserId ?? 0,
        receiverId: widget.receiverId,
        message: message,
        isRead: false,
        isReadByReceiver: false,
        isRequest: false,
        isDeleted: false,
        isPinned: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      setState(() {
        _messages.add(localMessage);
        _pendingMessages.add(pendingMessage);
      });
      
      _messageController.clear();
      _replyingTo = null;
      _scrollToBottom();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Mensagem salva. Será enviada quando houver conexão.',
              'Message saved. Will be sent when connection is available.',
            )),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      setState(() => _sending = false);
      return;
    }

    try {
      await _chatService.sendMessage(
        receiverId: widget.receiverId,
        message: message.isNotEmpty ? message : null,
        file: file,
        replyToId: replyToId ?? _replyingTo?.id,
      );
      
      _messageController.clear();
      _replyingTo = null;
      await _loadMessages(); // Recarregar para ver a mensagem enviada
    } catch (e) {
      // Se falhar, salvar como pendente
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      final pendingMessage = {
        'temp_id': tempId,
        'receiver_id': widget.receiverId,
        'message': message,
        'reply_to_id': replyToId ?? _replyingTo?.id,
        'file_path': file?.path,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await _offlineService.savePendingMessage(widget.receiverId, pendingMessage);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao enviar. Mensagem salva para envio posterior.',
              'Send error. Message saved for later.',
            )),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  /// Sincronizar mensagens pendentes quando voltar online
  Future<void> _syncPendingMessages() async {
    if (!_isOnline) return;
    
    try {
      final pending = await _offlineService.loadPendingMessages(widget.receiverId);
      if (pending.isEmpty) return;
      
      for (var pendingMsg in pending) {
        try {
          File? file;
          if (pendingMsg['file_path'] != null) {
            file = File(pendingMsg['file_path']);
            if (!await file.exists()) {
              file = null;
            }
          }
          
          await _chatService.sendMessage(
            receiverId: pendingMsg['receiver_id'] as int,
            message: pendingMsg['message'] as String?,
            file: file,
            replyToId: pendingMsg['reply_to_id'] as int?,
          );
          
          // Remover da lista de pendentes
          await _offlineService.removePendingMessage(
            widget.receiverId,
            pendingMsg['temp_id'] as String,
          );
          
          // Remover mensagem local com ID negativo
          setState(() {
            _messages.removeWhere((m) => m.id == -int.parse(pendingMsg['temp_id']));
            _pendingMessages.removeWhere((p) => p['temp_id'] == pendingMsg['temp_id']);
          });
        } catch (e) {
          print('Erro ao sincronizar mensagem pendente: $e');
          // Continuar com as próximas mensagens
        }
      }
      
      // Recarregar mensagens após sincronização
      await _loadMessages();
      
      if (mounted && pending.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              '${pending.length} mensagem(ns) sincronizada(s)',
              '${pending.length} message(s) synchronized',
            )),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao sincronizar mensagens pendentes: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _sendMessage(file: File(image.path));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        await _sendMessage(file: File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  // Gravar áudio
  Future<void> _startRecording() async {
    try {
      // Verificar permissão de microfone
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(
                context,
                'Permissão de microfone necessária',
                'Microphone permission required',
              )),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Verificar se o gravador está disponível
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _audioPath = '${directory.path}/audio_$timestamp.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _audioPath!,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });

        // Timer para atualizar duração
        _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        });

        // Feedback háptico
        HapticFeedback.mediumImpact();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(
                context,
                'Gravador de áudio não disponível',
                'Audio recorder not available',
              )),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao iniciar gravação: $e',
              'Error starting recording: $e',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    try {
      if (!_isRecording) return;

      _recordingTimer?.cancel();
      _recordingTimer = null;

      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });

      if (cancel || path == null) {
        // Cancelar gravação
        if (_audioPath != null) {
          try {
            final file = File(_audioPath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Erro ao deletar arquivo de áudio: $e');
          }
        }
        _audioPath = null;
        _recordingDuration = Duration.zero;
        return;
      }

      // Enviar áudio
      if (path != null && mounted) {
        await _sendMessage(file: File(path));
      }

      _audioPath = null;
      _recordingDuration = Duration.zero;
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao parar gravação: $e',
              'Error stopping recording: $e',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _deleteMessage(int messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.translateSync(
          context,
          'Excluir mensagem',
          'Delete message',
        )),
        content: Text(TranslationHelper.translateSync(
          context,
          'Tem certeza que deseja excluir esta mensagem?',
          'Are you sure you want to delete this message?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              TranslationHelper.translateSync(context, 'Excluir', 'Delete'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.deleteMessage(messageId);
        await _loadMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir mensagem: $e')),
          );
        }
      }
    }
  }

  Future<void> _togglePin(int messageId) async {
    try {
      await _chatService.togglePin(messageId);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fixar mensagem: $e')),
        );
      }
    }
  }

  Future<void> _reactToMessage(int messageId, String emoji) async {
    try {
      await _chatService.reactToMessage(messageId, emoji);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reagir: $e')),
        );
      }
    }
  }

  void _showReactionPicker(int messageId) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _reactToMessage(messageId, emoji);
              },
              child: Text(emoji, style: TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Filtrar mensagens para busca
  List<InternalChatMessage> _getFilteredMessages() {
    if (_searchQuery.isEmpty) {
      return _messages;
    }
    final query = _searchQuery.toLowerCase();
    return _messages.where((msg) {
      return msg.message.toLowerCase().contains(query) ||
          (msg.fileName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // Visualizar imagem em tela cheia
  void _showImageFullscreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reproduzir áudio
  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_isPlayingAudio && _currentAudioUrl == audioUrl) {
        // Se já está tocando, pausar
        await _audioPlayer?.stop();
        setState(() {
          _isPlayingAudio = false;
          _currentAudioUrl = null;
        });
        return;
      }

      // Parar áudio anterior se houver
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }

      _audioPlayer = AudioPlayer();
      await _audioPlayer!.play(UrlSource(audioUrl));
      
      setState(() {
        _isPlayingAudio = true;
        _currentAudioUrl = audioUrl;
      });

      // Quando terminar de tocar
      _audioPlayer!.onPlayerComplete.listen((_) {
        setState(() {
          _isPlayingAudio = false;
          _currentAudioUrl = null;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reproduzir áudio: $e')),
        );
      }
    }
  }

  // Baixar arquivo
  Future<void> _downloadFile(InternalChatMessage message) async {
    try {
      if (message.fileUrl == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = message.fileName ?? 'file_${message.id}';
      final filePath = '${directory.path}/$fileName';
      
      // Baixar arquivo
      final uri = Uri.parse(message.fileUrl!);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(
                context,
                'Arquivo baixado: $fileName',
                'File downloaded: $fileName',
              )),
              action: SnackBarAction(
                label: TranslationHelper.translateSync(context, 'Abrir', 'Open'),
                onPressed: () async {
                  final fileUri = Uri.file(filePath);
                  if (await canLaunchUrl(fileUri)) {
                    await launchUrl(fileUri);
                  }
                },
              ),
            ),
          );
        }
      } else {
        // Se falhar, tentar abrir URL
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar arquivo: $e')),
        );
      }
    }
  }

  // Compartilhar localização
  Future<void> _shareLocation() async {
    try {
      // Verificar permissões
      final locationPermission = await Permission.location.request();
      if (!locationPermission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permissão de localização negada')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final position = await Geolocator.getCurrentPosition();
      final locationUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      final locationMessage = TranslationHelper.translateSync(
        context,
        '📍 Minha localização: $locationUrl',
        '📍 My location: $locationUrl',
      );

      // Enviar mensagem de localização
      _messageController.text = locationMessage;
      await _sendMessage();
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter localização: $e')),
        );
      }
    }
  }

  // Editar mensagem
  void _startEditingMessage(InternalChatMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _editController = TextEditingController(text: message.message);
    });
  }

  Future<void> _saveEditedMessage() async {
    if (_editingMessageId == null || _editController == null) return;
    
    try {
      // Nota: A API pode não ter endpoint de edição, então vamos apenas atualizar localmente
      // Se houver endpoint, implementar aqui
      setState(() {
        _editingMessageId = null;
        _editController?.dispose();
        _editController = null;
      });
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar mensagem: $e')),
      );
    }
  }

  // Configurações de chat
  void _showSettingsDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color? selectedBtnColor = _userSettings['btn_color'] != null
        ? Color(int.parse(_userSettings['btn_color'].replaceFirst('#', '0xff')))
        : null;
    Color? selectedHeaderColor = _userSettings['header_color'] != null
        ? Color(int.parse(_userSettings['header_color'].replaceFirst('#', '0xff')))
        : null;
    Color? selectedFloatingBtnColor = _userSettings['floating_btn_color'] != null
        ? Color(int.parse(_userSettings['floating_btn_color'].replaceFirst('#', '0xff')))
        : null;
    
    String? chatName = _userSettings['chat_name'];
    String? chatAvatar = _userSettings['chat_avatar'];
    TextEditingController nameController = TextEditingController(text: chatName);
    String? selectedAvatar;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(TranslationHelper.translateSync(context, 'Configurações', 'Settings')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Foto do cabeçalho
                ListTile(
                  title: Text(TranslationHelper.translateSync(context, 'Foto do cabeçalho', 'Header photo')),
                  subtitle: Text(TranslationHelper.translateSync(
                    context,
                    'Foto exibida no cabeçalho do chat',
                    'Photo displayed in chat header',
                  )),
                  trailing: GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        // Upload da imagem (implementar upload para API)
                        // Por enquanto, salvar localmente
                        setDialogState(() {
                          selectedAvatar = image.path;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: selectedAvatar != null
                          ? FileImage(File(selectedAvatar!)) as ImageProvider
                          : (chatAvatar != null
                              ? CachedNetworkImageProvider(chatAvatar) as ImageProvider
                              : null),
                      child: selectedAvatar == null && chatAvatar == null
                          ? Icon(Icons.person)
                          : null,
                    ),
                  ),
                ),
                // Nome do cabeçalho
                ListTile(
                  title: Text(TranslationHelper.translateSync(context, 'Nome do cabeçalho', 'Header name')),
                  subtitle: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: TranslationHelper.translateSync(
                        context,
                        'Digite seu nome',
                        'Enter your name',
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(TranslationHelper.translateSync(context, 'Cor do botão', 'Button color')),
                  trailing: GestureDetector(
                    onTap: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (context) => SimpleColorPicker(
                          initialColor: selectedBtnColor ?? colorScheme.primary,
                        ),
                      );
                      if (color != null) {
                        setDialogState(() => selectedBtnColor = color);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedBtnColor ?? colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(TranslationHelper.translateSync(context, 'Cor do cabeçalho', 'Header color')),
                  trailing: GestureDetector(
                    onTap: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (context) => SimpleColorPicker(
                          initialColor: selectedHeaderColor ?? colorScheme.primary,
                        ),
                      );
                      if (color != null) {
                        setDialogState(() => selectedHeaderColor = color);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedHeaderColor ?? colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: Text(TranslationHelper.translateSync(context, 'Cor do botão flutuante', 'Floating button color')),
                  subtitle: Text(TranslationHelper.translateSync(
                    context,
                    'Cor do botão de chat flutuante',
                    'Floating chat button color',
                  )),
                  trailing: GestureDetector(
                    onTap: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (context) => SimpleColorPicker(
                          initialColor: selectedFloatingBtnColor ?? colorScheme.primary,
                        ),
                      );
                      if (color != null) {
                        setDialogState(() => selectedFloatingBtnColor = color);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selectedFloatingBtnColor ?? colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // TODO: Upload da foto se houver selectedAvatar
                  String? avatarUrl = selectedAvatar; // Substituir por URL após upload
                  
                  await _chatService.saveSettings(
                    btnColor: selectedBtnColor != null 
                        ? '#${selectedBtnColor!.value.toRadixString(16).substring(2)}'
                        : null,
                    headerColor: selectedHeaderColor != null
                        ? '#${selectedHeaderColor!.value.toRadixString(16).substring(2)}'
                        : null,
                    chatName: nameController.text.isNotEmpty ? nameController.text : null,
                    chatAvatar: avatarUrl,
                    floatingBtnColor: selectedFloatingBtnColor != null
                        ? '#${selectedFloatingBtnColor!.value.toRadixString(16).substring(2)}'
                        : null,
                  );
                  await _loadMessages(); // Recarregar para atualizar
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar: $e')),
                  );
                }
              },
              child: Text(TranslationHelper.translateSync(context, 'Salvar', 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadChatHistory() async {
    try {
      // Mostrar loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Baixar PDF do histórico
      final pdfBytes = await _chatService.downloadHistory(widget.receiverId);
      
      // Obter diretório de documentos
      final directory = await getApplicationDocumentsDirectory();
      
      // Criar nome do arquivo com data/hora
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      final fileName = 'chat_history_${widget.receiverId}_${dateFormat.format(DateTime.now())}.pdf';
      final filePath = '${directory.path}/$fileName';
      
      // Salvar arquivo
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      
      // Fechar dialog de loading
      if (mounted) Navigator.pop(context);
      
      // Mostrar mensagem de sucesso com opção de abrir/compartilhar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Histórico baixado com sucesso!',
              'History downloaded successfully!',
            )),
            action: SnackBarAction(
              label: TranslationHelper.translateSync(
                context,
                'Abrir',
                'Open',
              ),
              onPressed: () async {
                final uri = Uri.file(filePath);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  // Tentar compartilhar se não conseguir abrir
                  await Share.shareXFiles(
                    [XFile(filePath)],
                    text: TranslationHelper.translateSync(
                      context,
                      'Histórico do chat',
                      'Chat history',
                    ),
                  );
                }
              },
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Fechar dialog de loading se ainda estiver aberto
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao baixar histórico: $e',
              'Error downloading history: $e',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Erro ao baixar histórico do chat: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return TranslationHelper.translateSync(context, 'Hoje', 'Today');
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return TranslationHelper.translateSync(context, 'Ontem', 'Yesterday');
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final devices = await _chatService.getDevices();
      setState(() {
        _devices = devices;
        _loadingDevices = false;
      });
    } catch (e) {
      setState(() => _loadingDevices = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao carregar dispositivos: $e',
              'Error loading devices: $e',
            )),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPanicDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(TranslationHelper.translateSync(
              context,
              'Ação de Pânico',
              'Panic Action',
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TranslationHelper.translateSync(
              context,
              'Esta ação irá parar o motor do veículo selecionado. Tem certeza?',
              'This action will stop the engine of the selected vehicle. Are you sure?',
            )),
            SizedBox(height: 16),
            if (_loadingDevices)
              Center(child: CircularProgressIndicator())
            else if (_devices.isEmpty)
              TextButton(
                onPressed: () async {
                  await _loadDevices();
                },
                child: Text(TranslationHelper.translateSync(
                  context,
                  'Carregar dispositivos',
                  'Load devices',
                )),
              )
            else
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device['name'] ?? 'Dispositivo ${device['id']}'),
                      subtitle: Text(device['plate_number'] ?? ''),
                      onTap: () async {
                        Navigator.pop(context);
                        await _triggerPanic(device['id'] as int);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(TranslationHelper.translateSync(
              context,
              'Cancelar',
              'Cancel',
            )),
          ),
        ],
      ),
    );
    
    // Carregar dispositivos automaticamente ao abrir o diálogo
    if (_devices.isEmpty && !_loadingDevices) {
      _loadDevices();
    }
  }

  Future<void> _triggerPanic(int deviceId) async {
    // Confirmar novamente antes de executar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text(TranslationHelper.translateSync(
              context,
              'Confirmar Pânico',
              'Confirm Panic',
            )),
          ],
        ),
        content: Text(TranslationHelper.translateSync(
          context,
          'Tem certeza que deseja parar o motor deste veículo? Esta ação é irreversível.',
          'Are you sure you want to stop this vehicle\'s engine? This action is irreversible.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TranslationHelper.translateSync(
              context,
              'Cancelar',
              'Cancel',
            )),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(TranslationHelper.translateSync(
              context,
              'Confirmar',
              'Confirm',
            )),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Executar ação de pânico
      await _chatService.triggerPanicAction(deviceId);
      
      // Enviar mensagem no chat informando sobre a ação de pânico
      try {
        final deviceName = _devices.firstWhere(
          (d) => d['id'] == deviceId,
          orElse: () => {'name': 'Dispositivo $deviceId'},
        )['name'] as String;
        
        final panicMessage = TranslationHelper.translateSync(
          context,
          '🚨 AÇÃO DE PÂNICO EXECUTADA 🚨\n\nVeículo: $deviceName\nAção: Parada de motor\n\nEsta ação foi executada remotamente.',
          '🚨 PANIC ACTION EXECUTED 🚨\n\nVehicle: $deviceName\nAction: Engine stop\n\nThis action was executed remotely.',
        );
        
        await _chatService.sendMessage(
          receiverId: widget.receiverId,
          message: panicMessage,
        );
        
        // Disparar notificação push de pânico para o receptor
        await ChatNotificationService().notifyNewMessage(
          title: TranslationHelper.translateSync(
            context,
            '🚨 AÇÃO DE PÂNICO 🚨',
            '🚨 PANIC ACTION 🚨',
          ),
          body: panicMessage,
          data: {
            'type': 'panic_action',
            'device_id': deviceId.toString(),
            'device_name': deviceName,
            'receiver_id': widget.receiverId.toString(),
          },
          isPanic: true, // Marcar como pânico para som contínuo
        );
        
        // Recarregar mensagens para mostrar a mensagem de pânico
        await _loadMessages();
      } catch (msgError) {
        // Se falhar ao enviar mensagem, apenas logar (não é crítico)
        print('Erro ao enviar mensagem de pânico: $msgError');
      }
      
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Ação de pânico executada com sucesso',
              'Panic action executed successfully',
            )),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao executar ação de pânico: $e',
              'Error executing panic action: $e',
            )),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colorProvider = Provider.of<ColorProvider>(context);
    final btnColor = _userSettings['btn_color'] != null
        ? Color(int.parse(_userSettings['btn_color'].replaceFirst('#', '0xff')))
        : colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _userSettings['header_color'] != null
            ? Color(int.parse(_userSettings['header_color'].replaceFirst('#', '0xff')))
            : colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Row(
          children: [
            // Foto do usuário no cabeçalho
            if (_userSettings['chat_avatar'] != null)
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(_userSettings['chat_avatar']),
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                _userSettings['chat_name'] ?? TranslationHelper.translateSync(context, 'Chat', 'Chat'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            if (!_isOnline)
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.cloud_off,
                  size: 20,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        actions: [
          // Botão do UnnicaBot - OCULTO TEMPORARIAMENTE
          // IconButton(
          //   icon: Stack(
          //     children: [
          //       Icon(Icons.smart_toy, color: colorScheme.onPrimary),
          //       Positioned(
          //         right: 0,
          //         top: 0,
          //         child: Container(
          //           padding: EdgeInsets.all(2),
          //           decoration: BoxDecoration(
          //             color: Colors.blue,
          //             shape: BoxShape.circle,
          //           ),
          //           constraints: BoxConstraints(
          //             minWidth: 12,
          //             minHeight: 12,
          //           ),
          //           child: Text(
          //             'AI',
          //             style: TextStyle(
          //               fontSize: 6,
          //               color: Colors.white,
          //               fontWeight: FontWeight.bold,
          //             ),
          //             textAlign: TextAlign.center,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          //   tooltip: TranslationHelper.translateSync(context, 'UnnicaBot', 'UnnicaBot'),
          //   onPressed: () async {
          //     final token = StaticVarMethod.user_api_hash;
          //     if (token != null && token.isNotEmpty) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => UnnicaBotChatScreen(token: token),
          //         ),
          //       );
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text(
          //             TranslationHelper.translateSync(
          //               context,
          //               'Token de autenticação não encontrado',
          //               'Authentication token not found',
          //             ),
          //           ),
          //           backgroundColor: Colors.red,
          //         ),
          //       );
          //     }
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: theme.scaffoldBackgroundColor,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão de Pânico - apenas para usuário comum (não admin/gerente)
                      if (!_isAdminOrManager) ...[
                        ListTile(
                          leading: Icon(Icons.warning, color: colorScheme.error),
                          title: Text(
                            TranslationHelper.translateSync(
                              context,
                              'Ação de Pânico',
                              'Panic Action',
                            ),
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            TranslationHelper.translateSync(
                              context,
                              'Parar motor do veículo',
                              'Stop vehicle engine',
                            ),
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showPanicDialog();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                // Lista de mensagens
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            TranslationHelper.translateSync(
                              context,
                              'Nenhuma mensagem ainda',
                              'No messages yet',
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMessages,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: _getFilteredMessages().length + (_typingUsers.isNotEmpty ? 1 : 0),
                            itemBuilder: (context, index) {
                              final filteredMessages = _getFilteredMessages();
                              // Indicador de digitação
                              if (index == filteredMessages.length && _typingUsers.isNotEmpty) {
                                return Padding(
                                  padding: EdgeInsets.only(left: 16, bottom: 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        TranslationHelper.translateSync(
                                          context,
                                          'Digitando...',
                                          'Typing...',
                                        ),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final message = filteredMessages[index];
                              final isSent = message.senderId == _currentUserId;
                              final showDate = index == 0 ||
                                  (index > 0 && filteredMessages[index - 1].createdAt.day != message.createdAt.day);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showDate)
                                    Center(
                                      child: Container(
                                        margin: EdgeInsets.symmetric(vertical: 8),
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _formatDate(message.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ChatMessageBubble(
                                    message: message,
                                    isSent: isSent,
                                    colorProvider: colorProvider,
                                    btnColor: btnColor,
                                    onReply: () {
                                      setState(() {
                                        _replyingTo = message;
                                      });
                                    },
                                    onReact: () => _showReactionPicker(message.id),
                                    onDelete: isSent ? () => _deleteMessage(message.id) : null,
                                    onPin: () => _togglePin(message.id),
                                    onEdit: isSent && !message.isDeleted ? () => _startEditingMessage(message) : null,
                                    onImageTap: message.isImage ? () => _showImageFullscreen(message.fileUrl!) : null,
                                    onAudioTap: message.isAudio ? () => _playAudio(message.fileUrl!) : null,
                                    onFileDownload: message.hasFile ? () => _downloadFile(message) : null,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                ),

                // Mensagem sendo respondida
                if (_replyingTo != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    color: theme.colorScheme.surfaceVariant,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TranslationHelper.translateSync(
                                  context,
                                  'Respondendo a:',
                                  'Replying to:',
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                _replyingTo!.message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _replyingTo = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // Campo de entrada
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // Campo de texto
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: TranslationHelper.translateSync(
                                      context,
                                      'Digite uma mensagem...',
                                      'Type a message...',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceVariant,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              // Botão enviar
                              _sending
                                  ? Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.send,
                                        color: btnColor,
                                      ),
                                      onPressed: () => _sendMessage(),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Widget simples para seleção de cor
class SimpleColorPicker extends StatelessWidget {
  final Color initialColor;
  
  const SimpleColorPicker({Key? key, required this.initialColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
    ];

    return AlertDialog(
      title: Text(TranslationHelper.translateSync(context, 'Selecionar cor', 'Select color')),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: colors.map((color) {
          return GestureDetector(
            onTap: () => Navigator.pop(context, color),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == initialColor ? colorScheme.primary : colorScheme.outline,
                  width: color == initialColor ? 3 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
        ),
      ],
    );
  }
}
