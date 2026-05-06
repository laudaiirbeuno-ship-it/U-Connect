import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/ui/unnica_bot/unnica_bot_service.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/screens/geofences/GeofenceAdd.dart';
import 'package:uconnect/data/screens/router/views/router_screen.dart';
import 'package:uconnect/data/screens/reports/views/reports_screen.dart';
import 'package:uconnect/data/screens/route_history/views/route_history_screen.dart';
import 'package:uconnect/data/model/ReportModel.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/data/model/devices.dart';

/// Tela do chat do UnnicaBot com paridade total com plataforma web
class UnnicaBotChatScreen extends StatefulWidget {
  final String token;
  final BotStatus? status;

  const UnnicaBotChatScreen({
    Key? key,
    required this.token,
    this.status,
  }) : super(key: key);

  @override
  State<UnnicaBotChatScreen> createState() => _UnnicaBotChatScreenState();
}

class _UnnicaBotChatScreenState extends State<UnnicaBotChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UnnicaBotService _service = UnnicaBotService();
  
  List<Map<String, String>> _history = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  BotStatus? _status;
  bool _showShortcuts = true;
  bool _filterReportsOnly = false;
  String _currentMode = 'default';
  Map<String, dynamic> _currentPayload = {};
  Timer? _followUpTimer;
  String? _userFirstName;
  
  // Novas funcionalidades
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  
  static const String _historyKeyPrefix = 'unnica_tracker_chat_v3_';
  static const int _maxHistoryLength = 10;
  
  // Chips de ação rápida - cores serão definidas dinamicamente pelo ColorProvider
  List<ShortcutButton> _getAllUserShortcuts(ColorProvider colorProvider) {
    return [
      ShortcutButton(
        icon: Icons.description,
        label: TranslationHelper.translateSync(context, 'Relatórios', 'Reports'),
        message: TranslationHelper.translateSync(context, 'relatórios', 'reports'),
        color: colorProvider.primaryColor,
      ),
      ShortcutButton(
        icon: Icons.history,
        label: TranslationHelper.translateSync(context, 'Histórico', 'History'),
        message: TranslationHelper.translateSync(context, 'histórico', 'history'),
        color: colorProvider.primaryColor,
      ),
    ];
  }
  
  // Chips adicionais para Admin/Gerente
  List<ShortcutButton> _getAdminShortcuts(ColorProvider colorProvider) {
    return [
      ShortcutButton(
        icon: Icons.person_add,
        label: TranslationHelper.translateSync(context, 'Cadastro', 'Registration'),
        message: 'INICIAR_CADASTRO',
        color: colorProvider.primaryColor,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _service.token = widget.token;
    _status = widget.status;
    
    _loadUserFirstName();
    _loadHistory();
    _initializeSpeech();
    
    if (_status == null) {
      _loadStatus();
    }
    
    // Se não houver histórico, adicionar mensagem inicial
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(
        text: TranslationHelper.translateSync(
          context,
          'Olá! Sou o UnnicaBot, seu assistente de telemetria. Como posso ajudar?',
          'Hello! I\'m UnnicaBot, your telemetry assistant. How can I help you?',
        ),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _initializeSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (mounted) {
          setState(() {
            _isListening = status == 'listening';
          });
        }
      },
      onError: (error) {
        print('Erro no reconhecimento de voz: $error');
        if (mounted) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
  }

  Future<void> _loadUserFirstName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final client = userData['user']['client'];
        _userFirstName = client['first_name'] ?? TranslationHelper.translateSync(context, 'Usuário', 'User');
      }
    } catch (e) {
      print('Erro ao carregar nome do usuário: $e');
    }
  }

  Future<String> _getUserHash() async {
    final token = StaticVarMethod.user_api_hash;
    if (token != null && 
        token.isNotEmpty && 
        token != "\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G") {
      return token;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userHash = prefs.getString('user_api_hash');
    return userHash ?? 'default';
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userHash = await _getUserHash();
      final historyKey = '${_historyKeyPrefix}$userHash';
      
      final historyJson = prefs.getString(historyKey);
      if (historyJson != null) {
        final historyData = json.decode(historyJson) as Map<String, dynamic>;
        
        final messagesList = historyData['messages'] as List?;
        if (messagesList != null && messagesList.isNotEmpty) {
          setState(() {
            _messages = messagesList.map((msg) => ChatMessage.fromJson(msg)).toList();
            _showShortcuts = false; // Esconder atalhos se houver histórico
          });
        }
        
        final apiHistory = historyData['apiHistory'] as List?;
        if (apiHistory != null) {
          _history = apiHistory.map((h) => Map<String, String>.from(h)).toList();
        }
        
        final mode = historyData['mode'] as String?;
        if (mode != null) {
          _currentMode = mode;
        }
        
        final payload = historyData['payload'] as Map<String, dynamic>?;
        if (payload != null) {
          _currentPayload = payload;
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('⚠️ Erro ao carregar histórico: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userHash = await _getUserHash();
      final historyKey = '${_historyKeyPrefix}$userHash';
      
      // Limitar histórico a 10 mensagens
      final messagesToSave = _messages.length > _maxHistoryLength
          ? _messages.sublist(_messages.length - _maxHistoryLength)
          : _messages;
      
      final historyData = {
        'messages': messagesToSave.map((msg) => msg.toJson()).toList(),
        'apiHistory': _history.length > _maxHistoryLength
            ? _history.sublist(_history.length - _maxHistoryLength)
            : _history,
        'mode': _currentMode,
        'payload': _currentPayload,
        'lastUpdate': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(historyKey, json.encode(historyData));
    } catch (e) {
      print('⚠️ Erro ao salvar histórico: $e');
    }
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userHash = await _getUserHash();
      final historyKey = '${_historyKeyPrefix}$userHash';
      
      await prefs.remove(historyKey);
      
      setState(() {
        _history.clear();
        _messages.clear();
        _currentMode = 'default';
        _currentPayload = {};
        _showShortcuts = true;
        _messages.add(ChatMessage(
          text: TranslationHelper.translateSync(
            context,
            'Histórico limpo! Como posso ajudar?',
            'History cleared! How can I help?',
          ),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      
      _followUpTimer?.cancel();
      _followUpTimer = null;
    } catch (e) {
      print('⚠️ Erro ao limpar histórico: $e');
    }
  }

  Future<void> _loadStatus() async {
    final status = await _service.getStatus();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;
    
    // Adicionar mensagem do usuário
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _history.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();
    
    // Cancelar follow-up timer se existir
    _followUpTimer?.cancel();
    _followUpTimer = null;

    // Mensagem de espera customizada baseada no modo
    String waitingMessage = TranslationHelper.translateSync(
      context,
      'Aguarde um pouquinho, estou buscando as informações para você... 🔎',
      'Wait a moment, I\'m searching for information for you... 🔎',
    );
    if (_currentMode == 'health_diagnostic') {
      waitingMessage = TranslationHelper.translateSync(
        context,
        'Analisando a saúde da sua frota... 🧠🔍',
        'Analyzing your fleet\'s health... 🧠🔍',
      );
    }
    
    // Adicionar mensagem de espera
    setState(() {
      _messages.add(ChatMessage(
        text: waitingMessage,
        isUser: false,
        timestamp: DateTime.now(),
        isWaiting: true,
      ));
    });
    _scrollToBottom();

    // Delay proporcional ao tamanho da resposta (simulado)
    final delay = Duration(milliseconds: 1500);
    await Future.delayed(delay);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Enviar para o bot
    final response = await _service.sendMessage(
      message: text,
      history: _history,
      mode: _currentMode,
      payload: _currentPayload,
    );

    if (!mounted) return;

    // Remover mensagem de espera
    setState(() {
      _messages.removeWhere((msg) => msg.isWaiting == true);
      _isLoading = false;
    });

    if (response.status == 1) {
      // Atualizar modo e payload se necessário
      if (response.mode.isNotEmpty && response.mode != 'default') {
        _currentMode = response.mode;
      }
      if (response.payload.isNotEmpty) {
        _currentPayload = response.payload;
      }

      // Adicionar resposta do bot
      setState(() {
        _messages.add(ChatMessage(
          text: response.response ?? TranslationHelper.translateSync(context, 'Sem resposta', 'No response'),
          isUser: false,
          timestamp: DateTime.now(),
          type: response.type,
          buttons: response.buttons,
          url: response.url,
          devices: response.devices,
          reportTypes: response.reportTypes,
          table: response.table,
          totals: response.totals,
          detailedSummary: response.detailedSummary,
          data: response.data,
          gmaps: response.payload['gmaps']?.toString(),
        ));
        
        if (response.response != null) {
          _history.add({'role': 'model', 'text': response.response!});
          
          // Limitar histórico a 10 mensagens
          if (_history.length > _maxHistoryLength) {
            _history.removeAt(0);
          }
        }
      });

      // Haptic feedback ao receber resposta
      HapticFeedback.lightImpact();

      // Tocar som de notificação
      _playNotificationSound();

      // Verificar se há URL de PDF para download
      if (response.url != null && response.url!.endsWith('.pdf')) {
        _downloadPDF(response.url!);
      }

      // Tratar tipos especiais de resposta
      _handleSpecialResponse(response);
      
      // Configurar follow-up para comandos curtos
      if (text.length < 20 || text.contains('```')) {
        _setupFollowUp();
      }
    } else {
      // Mostrar erro
      String errorMessage = TranslationHelper.translateSync(
        context,
        'Puxa, tive um probleminha técnico. Pode tentar de novo?',
        'Oops, I had a technical issue. Can you try again?',
      );
      if (response.message != null && (response.message!.contains('sessão') || response.message!.contains('session'))) {
        errorMessage = TranslationHelper.translateSync(
          context,
          'Sua sessão expirou. Por favor, recarregue a página.',
          'Your session has expired. Please reload the page.',
        );
      } else if (response.message != null && (response.message!.contains('conexão') || response.message!.contains('connection'))) {
        errorMessage = TranslationHelper.translateSync(
          context,
          'Estou sem sinal por aqui. Verifique sua conexão!',
          'I\'m having connection issues. Check your connection!',
        );
      }
      
      setState(() {
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    }

    await _saveHistory();
    _scrollToBottom();
  }

  void _setupFollowUp() {
    _followUpTimer?.cancel();
    _followUpTimer = Timer(Duration(minutes: 30), () {
      if (mounted && _messages.isNotEmpty) {
        final firstName = _userFirstName ?? TranslationHelper.translateSync(context, 'Usuário', 'User');
        setState(() {
          _messages.add(ChatMessage(
            text: TranslationHelper.translateSync(
              context,
              'E aí, **$firstName**! Deu certo o envio dos comandos? O rastreador já conectou na plataforma? 😊',
              'Hey, **$firstName**! Did the commands work? Has the tracker connected to the platform? 😊',
            ),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
        _saveHistory();
      }
    });
  }

  void _handleSpecialResponse(ChatResponse response) {
    switch (response.type) {
      case 'redirect':
        if (response.url != null) {
          _openUrl(response.url!);
        }
        break;
      case 'vehicle_selection':
      case 'vehicle_selection_sms':
      case 'vehicle_selection_diagnostic':
        _showVehicleSelection(response.devices);
        break;
      case 'report_type_selection':
        _showReportTypeSelection(response.reportTypes);
        break;
      case 'date_selection':
      case 'financial_date_selection':
        _showDateSelection(response.data);
        break;
      case 'report_result':
        // Abre a tela de relatórios com os dados do bot
        _openReportsScreen(response);
        break;
      case 'history_result':
      case 'detailed_history':
        // Abre a tela de histórico com os dados do bot
        _openHistoryScreen(response);
        break;
      case 'trigger_geofence_draw':
        _openGeofenceDrawer(response.data);
        break;
      case 'trigger_route_draw':
        _openRouteDrawer(response.data);
        break;
      case 'buttons':
        // Botões já são renderizados na mensagem
        break;
      // Adicionar outros tipos conforme necessário
    }
  }

  void _openGeofenceDrawer(Map<String, dynamic>? data) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GeofenceAddPage(),
      ),
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Geofence criada com sucesso!',
              'Geofence created successfully!',
            )),
            backgroundColor: colorProvider.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _openRouteDrawer(Map<String, dynamic>? data) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RouterScreen(),
      ),
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Rota criada com sucesso!',
              'Route created successfully!',
            )),
            backgroundColor: colorProvider.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showVehicleSelection(List<dynamic>? devices) {
    if (devices == null || devices.isEmpty) return;

    // Verificar se permite seleção múltipla baseado no payload
    bool allowMultiSelect = _currentPayload['multi_select'] == true || 
                           _currentPayload['allow_multiple'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Text(
              allowMultiSelect 
                ? TranslationHelper.translateSync(context, 'Selecione os veículos', 'Select vehicles')
                : TranslationHelper.translateSync(context, 'Selecione um veículo', 'Select a vehicle'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  // Buscar o nome do veículo em vários campos possíveis
                  final deviceName = device['display'] ?? 
                                    device['name'] ?? 
                                    device['device_name'] ?? 
                                    device['vehicle_name'] ?? 
                                    device['label'] ?? 
                                    '';
                  final devicePlate = device['plate'] ?? 
                                   device['plate_number'] ?? 
                                   device['plateNumber'] ?? 
                                   '';
                  final deviceId = device['id']?.toString() ?? '';
                  
                  // Se ainda não tiver nome, tentar buscar do ObjectStore
                  String finalDeviceName = deviceName;
                  if (finalDeviceName.isEmpty && deviceId.isNotEmpty) {
                    try {
                      final objectStore = Provider.of<ObjectStore>(context, listen: false);
                      final vehicle = objectStore.objects.firstWhere(
                        (v) => v.id?.toString() == deviceId,
                        orElse: () {
                          // Retornar um deviceItems vazio se não encontrar
                          final emptyDevice = deviceItems();
                          return emptyDevice;
                        },
                      );
                      if (vehicle.name != null && vehicle.name!.isNotEmpty) {
                        finalDeviceName = vehicle.name!;
                      }
                    } catch (e) {
                      // Ignorar erro
                    }
                  }
                  
                  // Se ainda não tiver nome, usar o ID como fallback
                  if (finalDeviceName.isEmpty) {
                    finalDeviceName = 'Veículo $deviceId';
                  }
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        
                        // Atualizar payload com o veículo selecionado antes de enviar
                        setState(() {
                          _currentPayload['vehicle_id'] = deviceId;
                          _currentPayload['device_id'] = deviceId;
                          if (finalDeviceName.isNotEmpty) {
                            _currentPayload['vehicle_name'] = finalDeviceName;
                            _currentPayload['device_name'] = finalDeviceName;
                          }
                        });
                        
                        // Salvar histórico atualizado
                        _saveHistory();
                        
                        if (allowMultiSelect) {
                          // Para múltipla seleção, envia apenas o ID selecionado
                          _messageController.text = deviceId;
                        } else {
                          // Para seleção única, envia o ID
                          _messageController.text = deviceId;
                        }
                        
                        // Aguardar um pouco para garantir que o estado foi atualizado
                        Future.delayed(Duration(milliseconds: 100), () {
                          _sendMessage();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  finalDeviceName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (devicePlate.isNotEmpty)
                                  Text(
                                    devicePlate,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.send, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (allowMultiSelect && devices.length > 1) ...[
              SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final allIds = devices
                      .map((d) => d['id']?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .join(',');
                  _messageController.text = allIds;
                  _sendMessage();
                },
                icon: Icon(Icons.select_all),
                label: Text(TranslationHelper.translateSync(context, 'Enviar todos', 'Send all')),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportTypeSelection(List<dynamic>? reportTypes) {
    if (reportTypes == null || reportTypes.isEmpty) return;

    // Verificar se permite seleção múltipla baseado no payload
    bool allowMultiSelect = _currentPayload['multi_select'] == true || 
                           _currentPayload['allow_multiple'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              allowMultiSelect 
                ? TranslationHelper.translateSync(context, 'Selecione os tipos de relatório', 'Select report types')
                : TranslationHelper.translateSync(context, 'Selecione o tipo de relatório', 'Select report type'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reportTypes.length,
                itemBuilder: (context, index) {
                  final type = reportTypes[index];
                  final typeName = type['name'] ?? type['id'] ?? '';
                  final typeDescription = type['description']?.toString();
                  final typeId = type['id']?.toString() ?? '';
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (allowMultiSelect) {
                          // Para múltipla seleção, envia apenas o ID selecionado
                          _messageController.text = typeId;
                        } else {
                          // Para seleção única, envia o ID
                          _messageController.text = typeId;
                        }
                        _sendMessage();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_chart, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  typeName.isNotEmpty ? typeName : 'Tipo $typeId',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (typeDescription != null && typeDescription.isNotEmpty)
                                  Text(
                                    typeDescription,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.send, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (allowMultiSelect && reportTypes.length > 1) ...[
              SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  final allIds = reportTypes
                      .map((t) => t['id']?.toString() ?? '')
                      .where((id) => id.isNotEmpty)
                      .join(',');
                  _messageController.text = allIds;
                  _sendMessage();
                },
                icon: Icon(Icons.select_all),
                label: Text(TranslationHelper.translateSync(context, 'Enviar todos', 'Send all')),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDateSelection(Map<String, dynamic>? data) {
    DateTime? selectedFromDate = DateTime.now().subtract(Duration(days: 7));
    DateTime? selectedToDate = DateTime.now();
    TimeOfDay? selectedFromTime = TimeOfDay.now();
    TimeOfDay? selectedToTime = TimeOfDay.now();
    bool isRangeSelection = data?['range'] == true || data?['type'] == 'range';
    bool includeTime = data?['include_time'] == true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isRangeSelection 
                ? TranslationHelper.translateSync(context, 'Selecione o período', 'Select period')
                : TranslationHelper.translateSync(context, 'Selecione a data', 'Select date'),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRangeSelection) ...[
                    // Data inicial
                    ListTile(
                      title: Text(TranslationHelper.translateSync(context, 'Data inicial', 'Start date')),
                      subtitle: Text(selectedFromDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedFromDate!)
                          : TranslationHelper.translateSync(context, 'Não selecionada', 'Not selected')),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedFromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Provider.of<ColorProvider>(context, listen: false).primaryColor ?? Colors.blue,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedFromDate = picked;
                          });
                        }
                      },
                    ),
                    if (includeTime)
                      ListTile(
                        title: Text(TranslationHelper.translateSync(context, 'Hora inicial', 'Start time')),
                        subtitle: Text(selectedFromTime?.format(context) ?? TranslationHelper.translateSync(context, 'Não selecionada', 'Not selected')),
                        trailing: Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedFromTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Provider.of<ColorProvider>(context, listen: false).primaryColor ?? Colors.blue,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedFromTime = picked;
                            });
                          }
                        },
                      ),
                    SizedBox(height: 16),
                    // Data final
                    ListTile(
                      title: Text(TranslationHelper.translateSync(context, 'Data final', 'End date')),
                      subtitle: Text(selectedToDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedToDate!)
                          : TranslationHelper.translateSync(context, 'Não selecionada', 'Not selected')),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedToDate ?? DateTime.now(),
                          firstDate: selectedFromDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Provider.of<ColorProvider>(context, listen: false).primaryColor ?? Colors.blue,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedToDate = picked;
                          });
                        }
                      },
                    ),
                    if (includeTime)
                      ListTile(
                        title: Text(TranslationHelper.translateSync(context, 'Hora final', 'End time')),
                        subtitle: Text(selectedToTime?.format(context) ?? TranslationHelper.translateSync(context, 'Não selecionada', 'Not selected')),
                        trailing: Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedToTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Provider.of<ColorProvider>(context, listen: false).primaryColor ?? Colors.blue,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedToTime = picked;
                            });
                          }
                        },
                      ),
                  ] else ...[
                    // Seleção de data única
                    ListTile(
                      title: Text(TranslationHelper.translateSync(context, 'Data', 'Date')),
                      subtitle: Text(selectedFromDate != null
                          ? DateFormat('dd/MM/yyyy').format(selectedFromDate!)
                          : TranslationHelper.translateSync(context, 'Não selecionada', 'Not selected')),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedFromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Provider.of<ColorProvider>(context, listen: false).primaryColor ?? Colors.blue,
                                  onPrimary: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedFromDate = picked;
                          });
                        }
                      },
                    ),
                    if (includeTime)
                      ListTile(
                        title: Text(TranslationHelper.translateSync(context, 'Hora', 'Time')),
                        subtitle: Text(selectedFromTime?.format(context) ?? TranslationHelper.translateSync(context, 'Não selecionada', 'Not selected')),
                        trailing: Icon(Icons.access_time),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedFromTime ?? TimeOfDay.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Provider.of<ColorProvider>(context, listen: false).primaryColor ?? Colors.blue,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedFromTime = picked;
                            });
                          }
                        },
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedFromDate == null || (isRangeSelection && selectedToDate == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(TranslationHelper.translateSync(
                          context,
                          'Por favor, selecione todas as datas necessárias',
                          'Please select all required dates',
                        )),
                      ),
                    );
                    return;
                  }

                  String dateString;
                  if (isRangeSelection) {
                    final fromDateTime = DateTime(
                      selectedFromDate!.year,
                      selectedFromDate!.month,
                      selectedFromDate!.day,
                      includeTime ? selectedFromTime!.hour : 0,
                      includeTime ? selectedFromTime!.minute : 0,
                    );
                    final toDateTime = DateTime(
                      selectedToDate!.year,
                      selectedToDate!.month,
                      selectedToDate!.day,
                      includeTime ? selectedToTime!.hour : 23,
                      includeTime ? selectedToTime!.minute : 59,
                    );
                    dateString = '${DateFormat('yyyy-MM-dd${includeTime ? ' HH:mm' : ''}').format(fromDateTime)} até ${DateFormat('yyyy-MM-dd${includeTime ? ' HH:mm' : ''}').format(toDateTime)}';
                  } else {
                    final dateTime = DateTime(
                      selectedFromDate!.year,
                      selectedFromDate!.month,
                      selectedFromDate!.day,
                      includeTime ? selectedFromTime!.hour : 0,
                      includeTime ? selectedFromTime!.minute : 0,
                    );
                    dateString = DateFormat('yyyy-MM-dd${includeTime ? ' HH:mm' : ''}').format(dateTime);
                  }

                  Navigator.pop(context);
                  _messageController.text = dateString;
                  _sendMessage();
                },
                child: Text(TranslationHelper.translateSync(context, 'Confirmar', 'Confirm')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openReportsScreen(ChatResponse response) {
    // Extrair dados do bot
    final data = response.data;
    if (data == null) return;
    
    final deviceId = data['vehicle_id'] ?? data['device_id'];
    final deviceName = data['device_name'] ?? data['vehicle_name'] ?? 'N/A';
    final reportTypeId = data['report_type'];
    final reportTypeName = data['report_name'] ?? data['report_type'] ?? 'Relatório';
    final dateFrom = data['date_from'];
    final dateTo = data['date_to'];
    final totals = data['totals'];
    final table = data['table'];
    final downloadUrl = data['download_url'];
    final mapLink = data['map_link'];
    
    // Converter dados para GeneratedReport - EXATAMENTE como nas páginas originais
    // Os dados do bot podem vir em diferentes formatos, precisamos estruturar igual à API
    Map<String, dynamic>? reportData;
    
    // Se houver dados diretos na resposta do bot, usar eles
    if (data.containsKey('items') || data.containsKey('totals') || data.containsKey('data')) {
      reportData = Map<String, dynamic>.from(data);
      // Remover campos de metadados
      reportData.remove('url');
      reportData.remove('status');
      reportData.remove('message');
      reportData.remove('vehicle_id');
      reportData.remove('device_id');
      reportData.remove('vehicle_name');
      reportData.remove('device_name');
      reportData.remove('report_type');
      reportData.remove('report_name');
      reportData.remove('date_from');
      reportData.remove('date_to');
      reportData.remove('download_url');
      reportData.remove('map_link');
      
      // Se houver 'data' dentro da resposta, usar esse como dados principais
      if (reportData.containsKey('data') && reportData['data'] is Map) {
        final innerData = reportData['data'] as Map<String, dynamic>;
        reportData = Map<String, dynamic>.from(innerData);
      }
    } else {
      // Construir estrutura de dados manualmente
      reportData = <String, dynamic>{};
      if (totals != null) reportData['totals'] = totals;
      if (table != null) reportData['table'] = table;
      if (downloadUrl != null) reportData['download_url'] = downloadUrl;
      if (mapLink != null) reportData['map_link'] = mapLink;
      
      // Se não houver dados válidos, usar null
      if (reportData.isEmpty) {
        reportData = null;
      }
    }
    
    // Converter datas
    DateTime? startDateParsed;
    DateTime? endDateParsed;
    
    if (dateFrom != null) {
      if (dateFrom is String) {
        startDateParsed = DateTime.tryParse(dateFrom);
      } else if (dateFrom is DateTime) {
        startDateParsed = dateFrom;
      }
    }
    
    if (dateTo != null) {
      if (dateTo is String) {
        endDateParsed = DateTime.tryParse(dateTo);
      } else if (dateTo is DateTime) {
        endDateParsed = dateTo;
      }
    }
    
    final report = GeneratedReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: reportTypeName,
      type: reportTypeId?.toString() ?? '',
      url: downloadUrl,
      data: reportData,
      createdAt: DateTime.now(),
      deviceId: deviceId is int ? deviceId : (deviceId != null ? int.tryParse(deviceId.toString()) : null),
      deviceName: deviceName.toString(),
      startDate: startDateParsed,
      endDate: endDateParsed,
    );
    
    // Criar ReportType
    final reportType = ReportType(
      id: reportTypeId is int ? reportTypeId : (reportTypeId != null ? int.tryParse(reportTypeId.toString()) : null),
      title: reportTypeName,
      value: reportTypeId?.toString(),
    );
    
    // Obter ColorProvider
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    
    // Usar o mesmo modal da página de relatórios (função pública)
    ReportsScreen.showReportModalFromBot(
      context,
      colorProvider,
      report: report,
      reportType: reportType,
      deviceName: deviceName.toString(),
      startDate: report.startDate ?? DateTime.now().subtract(Duration(days: 1)),
      endDate: report.endDate ?? DateTime.now(),
    );
  }

  void _openHistoryScreen(ChatResponse response) {
    // Extrair dados do bot
    final data = response.data;
    if (data == null) return;
    
    final deviceName = data['device_name'] ?? data['vehicle_name'] ?? 'Dispositivo';
    final pointsData = data['points'];
    final dateFrom = data['date_from'];
    final dateTo = data['date_to'];
    
    // Converter pontos para HistoryPoint - EXATAMENTE como nas páginas originais
    // A estrutura pode vir como data['items'] = [grupos], cada grupo tem items[] com os pontos
    List<HistoryPoint> points = [];
    
    if (pointsData != null) {
      // Estrutura 1: data['items'] = [grupos], cada grupo tem items[]
      if (pointsData is Map && pointsData['items'] != null && pointsData['items'] is List) {
        final grupos = pointsData['items'] as List;
        for (var grupo in grupos) {
          if (grupo is Map && grupo['items'] != null && grupo['items'] is List) {
            final grupoItems = grupo['items'] as List;
            for (var item in grupoItems) {
              try {
                if (item is Map) {
                  final itemMap = item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item);
                  final point = HistoryPoint.fromJson(itemMap);
                  points.add(point);
                }
              } catch (e) {
                print('⚠️ Erro ao parsear item: $e');
              }
            }
          }
        }
      }
      // Estrutura 2: Lista direta de pontos
      else if (pointsData is List) {
        for (var pointData in pointsData) {
          if (pointData is Map) {
            try {
              final pointMap = pointData is Map<String, dynamic>
                  ? pointData
                  : Map<String, dynamic>.from(pointData);
              final point = HistoryPoint.fromJson(pointMap);
              points.add(point);
            } catch (e) {
              print('⚠️ Erro ao parsear ponto: $e');
            }
          }
        }
      }
      // Estrutura 3: Map com 'messages' ou 'data'
      else if (pointsData is Map) {
        if (pointsData['messages'] != null && pointsData['messages'] is List) {
          points = (pointsData['messages'] as List)
              .map((item) {
                try {
                  return HistoryPoint.fromJson(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item));
                } catch (e) {
                  print('⚠️ Erro ao parsear item: $e');
                  return null;
                }
              })
              .whereType<HistoryPoint>()
              .toList();
        } else if (pointsData['data'] != null && pointsData['data'] is List) {
          points = (pointsData['data'] as List)
              .map((item) {
                try {
                  return HistoryPoint.fromJson(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item));
                } catch (e) {
                  print('⚠️ Erro ao parsear item: $e');
                  return null;
                }
              })
              .whereType<HistoryPoint>()
              .toList();
        }
      }
    }
    
    // Filtrar apenas pontos com localização válida
    final validPoints = points.where((p) => p.latitude != null && p.longitude != null).toList();
    
    if (validPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(
            context,
            'Nenhum ponto com localização válida encontrado',
            'No valid location points found',
          )),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Converter datas
    DateTime startDate = DateTime.now().subtract(Duration(days: 1));
    DateTime endDate = DateTime.now();
    
    if (dateFrom != null) {
      final parsed = DateTime.tryParse(dateFrom.toString());
      if (parsed != null) startDate = parsed;
    }
    
    if (dateTo != null) {
      final parsed = DateTime.tryParse(dateTo.toString());
      if (parsed != null) endDate = parsed;
    }
    
    // Obter ColorProvider
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    
    // Usar o mesmo modal da página de histórico (função pública)
    RouteHistoryScreen.showRouteModalFromBot(
      context,
      colorProvider,
      points: validPoints,
      startDate: startDate,
      endDate: endDate,
      deviceName: deviceName.toString(),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _resetChat() {
    _clearHistory();
    _currentMode = 'default';
    _currentPayload = {};
    _showShortcuts = true;
  }

  void _goBackToMenu() {
    setState(() {
      _messages.clear();
      _history.clear();
      _currentMode = 'default';
      _currentPayload = {};
      _showShortcuts = true;
      _messages.add(ChatMessage(
        text: 'Olá! Sou o UnnicaBot, seu assistente de telemetria. Como posso ajudar?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _saveHistory();
  }

  List<ChatMessage> get _filteredMessages {
    if (!_filterReportsOnly) return _messages;
    return _messages.where((msg) => 
      msg.type == 'report_result' || 
      msg.text.toLowerCase().contains('relatório') ||
      msg.isUser
    ).toList();
  }

  List<ShortcutButton> _getAvailableShortcuts(ColorProvider colorProvider) {
    if (_status == null) return _getAllUserShortcuts(colorProvider);
    
    if (_status!.isAdmin || _status!.isManager) {
      return [..._getAllUserShortcuts(colorProvider), ..._getAdminShortcuts(colorProvider)];
    }
    
    return _getAllUserShortcuts(colorProvider);
  }

  Future<void> _playNotificationSound() async {
    try {
      // Tentar tocar som de notificação do app
      await _audioPlayer.play(AssetSource('audio/notification.mp3'));
    } catch (e) {
      // Se não encontrar o arquivo, usar haptic feedback como fallback
      HapticFeedback.mediumImpact();
      print('Erro ao tocar som: $e');
    }
  }

  Future<void> _downloadPDF(String url) async {
    try {
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(TranslationHelper.translateSync(context, 'Baixando PDF...', 'Downloading PDF...')),
            ],
          ),
        ),
      );

      // Fazer download do PDF
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Obter diretório de downloads
        final directory = await getApplicationDocumentsDirectory();
        String fileName = url.split('/').last;
        if (!fileName.endsWith('.pdf')) {
          fileName = 'unnicabot_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        }
        final filePath = '${directory.path}/$fileName';
        
        // Salvar arquivo
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        // Fechar dialog de carregamento
        if (mounted) Navigator.pop(context);
        
        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'PDF baixado com sucesso!', 'PDF downloaded successfully!')),
              action: SnackBarAction(
                label: 'Abrir',
                onPressed: () async {
                  final uri = Uri.file(filePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.translateSync(context, 'Erro ao baixar PDF', 'Error downloading PDF')),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationHelper.translateSync(
              context,
              'Erro ao baixar PDF: $e',
              'Error downloading PDF: $e',
            )),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      print('Erro ao baixar PDF: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(
            context,
            'Reconhecimento de voz não disponível',
            'Speech recognition not available',
          )),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Solicitar permissão de microfone
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationHelper.translateSync(
            context,
            'Permissão de microfone necessária',
            'Microphone permission required',
          )),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          setState(() {
            _messageController.text = result.recognizedWords;
            _isListening = false;
          });
          
          // Tocar som de confirmação
          HapticFeedback.lightImpact();
          _playNotificationSound();
        }
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
      localeId: 'pt_BR', // Português do Brasil
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _followUpTimer?.cancel();
    _audioPlayer.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.white),
                SizedBox(width: 8),
                Text(TranslationHelper.translateSync(context, 'UnnicaBot', 'UnnicaBot')),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AI',
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: colorProvider.secondaryColor, // Cor secundária no fundo do cabeçalho
            actions: [
              // Botão de filtro
              IconButton(
                icon: Icon(
                  _filterReportsOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _filterReportsOnly = !_filterReportsOnly;
                  });
                },
                tooltip: TranslationHelper.translateSync(context, 'Filtrar apenas relatórios', 'Filter reports only'),
              ),
              // Botão para limpar histórico
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(TranslationHelper.translateSync(context, 'Limpar Histórico', 'Clear History')),
                      content: Text(TranslationHelper.translateSync(
                        context,
                        'Deseja limpar todo o histórico de conversação?',
                        'Do you want to clear all conversation history?',
                      )),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(TranslationHelper.translateSync(context, 'Cancelar', 'Cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _resetChat();
                          },
                          child: Text(
                        TranslationHelper.translateSync(context, 'Limpar', 'Clear'),
                        style: TextStyle(color: colorProvider.primaryColor),
                      ),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: TranslationHelper.translateSync(context, 'Limpar histórico', 'Clear history'),
              ),
              if (_status != null)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: Chip(
                      label: Text(
                        '${_status!.usageRemaining}/${_status!.usageLimit}',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: _status!.usageRemaining > 20
                          ? colorProvider.primaryColor.withOpacity(0.8)
                          : Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Chips de ação rápida
              if (_showShortcuts && _currentMode != 'health_diagnostic')
                _buildShortcutButtons(colorProvider),
              
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredMessages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _filteredMessages.length) {
                      return _buildLoadingIndicator(colorProvider);
                    }
                    return _buildMessage(_filteredMessages[index], colorProvider);
                  },
                ),
              ),
              _buildInputArea(colorProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortcutButtons(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TranslationHelper.translateSync(context, 'Atalhos rápidos', 'Quick shortcuts'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showShortcuts ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colorProvider.primaryColor,
                ),
                onPressed: () {
                  setState(() {
                    _showShortcuts = !_showShortcuts;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          if (_showShortcuts)
            SizedBox(height: 8),
          if (_showShortcuts)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _getAvailableShortcuts(colorProvider).map((shortcut) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _buildShortcutButton(shortcut, colorProvider),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShortcutButton(ShortcutButton shortcut, ColorProvider colorProvider) {
    final chipColor = shortcut.color ?? colorProvider.primaryColor;
    return InkWell(
      onTap: () {
        setState(() {
          _showShortcuts = false;
          // Se for cadastro, iniciar modo de cadastro
          if (shortcut.message == 'INICIAR_CADASTRO') {
            _currentMode = 'registration';
            _currentPayload = {};
          }
        });
        _messageController.text = shortcut.message;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: chipColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              shortcut.icon,
              size: 18,
              color: chipColor,
            ),
            SizedBox(width: 6),
            Text(
              shortcut.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message, ColorProvider colorProvider) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isUser
              ? colorProvider.primaryColor
              : message.isError
                  ? Colors.red.shade100
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                a: TextStyle(color: message.isUser ? Colors.white.withOpacity(0.8) : colorProvider.primaryColor),
                h1: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                h2: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                h3: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (message.type == 'report_result')
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showReportModalFromMessage(message),
                  icon: Icon(Icons.insert_chart, size: 18),
                  label: Text(TranslationHelper.translateSync(context, 'Ver Relatório Completo', 'View Full Report')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorProvider.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (message.buttons != null && message.buttons!.isNotEmpty)
              ...message.buttons!.map((button) => Padding(
                padding: EdgeInsets.only(top: 8),
                child: _buildInteractiveButton(button, message, colorProvider),
              )),
            if (message.gmaps != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openMapUrl(message.gmaps!),
                      icon: Icon(Icons.map, size: 18),
                      label: Text(TranslationHelper.translateSync(context, 'Ver no Mapa', 'View on Map')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorProvider.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _shareViaWhatsApp(message.gmaps!),
                      icon: Icon(Icons.share, size: 18),
                      label: Text(TranslationHelper.translateSync(context, 'Compartilhar', 'Share')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorProvider.primaryColor.withOpacity(0.8),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: message.isUser
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveButton(Map<String, dynamic> button, ChatMessage message, ColorProvider colorProvider) {
    final text = button['text']?.toString() ?? '';
    return ElevatedButton(
      onPressed: () => _handleButtonPress(button),
      style: ElevatedButton.styleFrom(
        backgroundColor: message.isUser
            ? Colors.white
            : colorProvider.primaryColor,
        foregroundColor: message.isUser
            ? colorProvider.primaryColor
            : Colors.white,
      ),
      child: Text(text),
    );
  }

  void _handleButtonPress(Map<String, dynamic> button) {
    final text = button['text']?.toString();
    final payload = button['payload'] as Map<String, dynamic>?;
    final mode = button['mode']?.toString() ?? 'default';

    if (text != null) {
      _messageController.text = text;
      _sendMessage();
    } else if (payload != null) {
      _currentPayload = payload;
      _currentMode = mode;
      _messageController.text = json.encode(payload);
      _sendMessage();
    }
  }

  Future<void> _openMapUrl(String gmapsUrl) async {
    final uri = Uri.parse(gmapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareViaWhatsApp(String gmapsUrl) async {
    final message = '📍 *Confira o trajeto realizado:* $gmapsUrl';
    final whatsappLink = WhatsAppUnilink(
      phoneNumber: '5511937758640',
      text: message,
    );
    
    final uri = await whatsappLink.asUri();
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showReportModalFromMessage(ChatMessage message) {
    if (message.type != 'report_result') return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PremiumReportModal(
        table: message.table,
        totals: message.totals,
        detailedSummary: message.detailedSummary,
        gmaps: message.gmaps,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLoadingIndicator(ColorProvider colorProvider) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorProvider.primaryColor),
              ),
            ),
            SizedBox(width: 8),
            Text(TranslationHelper.translateSync(context, 'Digitando...', 'Typing...')),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorProvider colorProvider) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botão de microfone
          if (_speechAvailable)
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : colorProvider.primaryColor,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
              tooltip: _isListening 
                ? TranslationHelper.translateSync(context, 'Parar gravação', 'Stop recording')
                : TranslationHelper.translateSync(context, 'Gravar voz', 'Record voice'),
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _isListening 
                  ? TranslationHelper.translateSync(context, 'Gravando...', 'Recording...')
                  : TranslationHelper.translateSync(context, 'Digite sua mensagem...', 'Type your message...'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorProvider.primaryColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorProvider.primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                suffixIcon: _isListening
                    ? Icon(Icons.mic, color: Colors.red)
                    : null,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading && !_isListening,
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: (_isLoading || _isListening) ? null : _sendMessage,
            child: Icon(Icons.send),
            backgroundColor: colorProvider.primaryColor,
          ),
        ],
      ),
    );
  }
}

/// Modal Premium para exibição de relatórios
class _PremiumReportModal extends StatelessWidget {
  final Map<String, dynamic>? table;
  final Map<String, dynamic>? totals;
  final Map<String, dynamic>? detailedSummary;
  final String? gmaps;
  final VoidCallback onClose;

  const _PremiumReportModal({
    Key? key,
    this.table,
    this.totals,
    this.detailedSummary,
    this.gmaps,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Premium
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorProvider.primaryColor,
                        colorProvider.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_chart, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Relatório Premium',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Análise detalhada',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
            
            // Conteúdo do relatório
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (totals != null) ...[
                      _buildSectionTitle(TranslationHelper.translateSync(context, 'Resumo Geral', 'General Summary')),
                      SizedBox(height: 12),
                      _buildTotalsCard(context, totals!, colorProvider),
                      SizedBox(height: 20),
                    ],
                    
                    if (table != null) ...[
                      _buildSectionTitle(TranslationHelper.translateSync(context, 'Dados Detalhados', 'Detailed Data')),
                      SizedBox(height: 12),
                      _buildTableCard(context, table!),
                      SizedBox(height: 20),
                    ],
                    
                    if (detailedSummary != null) ...[
                      _buildSectionTitle(TranslationHelper.translateSync(context, 'Análise Detalhada', 'Detailed Analysis')),
                      SizedBox(height: 12),
                      _buildDetailedSummaryCard(context, detailedSummary!),
                      SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer com ações
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  if (gmaps != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Implementar download PDF
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(TranslationHelper.translateSync(
                                context,
                                'Download em PDF em breve...',
                                'PDF download coming soon...',
                              )),
                              backgroundColor: colorProvider.primaryColor,
                            ),
                          );
                        },
                        icon: Icon(Icons.download),
                        label: Text(TranslationHelper.translateSync(context, 'Download PDF', 'Download PDF')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorProvider.primaryColor,
                          side: BorderSide(color: colorProvider.primaryColor),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: gmaps != null
                          ? () {
                              final uri = Uri.parse(gmaps!);
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(TranslationHelper.translateSync(
                                    context,
                                    'Abrindo no mapa...',
                                    'Opening on map...',
                                  )),
                                  backgroundColor: colorProvider.primaryColor,
                                ),
                              );
                            },
                      icon: Icon(Icons.map),
                      label: Text(TranslationHelper.translateSync(context, 'Ver no Mapa', 'View on Map')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorProvider.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, Map<String, dynamic> totals, ColorProvider colorProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: totals.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorProvider.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, Map<String, dynamic> table) {
    final headers = table['headers'] as List? ?? [];
    final rows = table['rows'] as List? ?? [];
    
    if (headers.isEmpty && rows.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(TranslationHelper.translateSync(
            context,
            'Sem dados de tabela disponíveis',
            'No table data available',
          )),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers.map((header) {
            return DataColumn(
              label: Text(
                header.toString(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
          rows: rows.map((row) {
            final rowData = row is List ? row : [];
            return DataRow(
              cells: rowData.map((cell) {
                return DataCell(_formatStatusCell(cell.toString()));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _formatStatusCell(String cellText) {
    // Formatar status visualmente
    if (cellText.toLowerCase().contains('online')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(0xFFdcfce7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Color(0xFF166534)),
            SizedBox(width: 4),
            Text(
              'Online',
              style: TextStyle(color: Color(0xFF166534), fontSize: 12),
            ),
          ],
        ),
      );
    } else if (cellText.toLowerCase().contains('offline')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Color(0xFFfee2e2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 14, color: Color(0xFF991b1b)),
            SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(color: Color(0xFF991b1b), fontSize: 12),
            ),
          ],
        ),
      );
    }
    
    return Text(cellText);
  }

  Widget _buildDetailedSummaryCard(BuildContext context, Map<String, dynamic> summary) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: summary.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    entry.value.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  Divider(height: 24),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final bool isWaiting;
  final String? type;
  final List<dynamic>? buttons;
  final String? url;
  final List<dynamic>? devices;
  final List<dynamic>? reportTypes;
  final Map<String, dynamic>? table;
  final Map<String, dynamic>? totals;
  final Map<String, dynamic>? detailedSummary;
  final Map<String, dynamic>? data;
  final String? gmaps;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.isWaiting = false,
    this.type,
    this.buttons,
    this.url,
    this.devices,
    this.reportTypes,
    this.table,
    this.totals,
    this.detailedSummary,
    this.data,
    this.gmaps,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'isWaiting': isWaiting,
      'type': type,
      'buttons': buttons,
      'url': url,
      'devices': devices,
      'reportTypes': reportTypes,
      'table': table,
      'totals': totals,
      'detailedSummary': detailedSummary,
      'data': data,
      'gmaps': gmaps,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      isError: json['isError'] ?? false,
      isWaiting: json['isWaiting'] ?? false,
      type: json['type'],
      buttons: json['buttons'],
      url: json['url'],
      devices: json['devices'],
      reportTypes: json['reportTypes'],
      table: json['table'],
      totals: json['totals'],
      detailedSummary: json['detailedSummary'],
      data: json['data'],
      gmaps: json['gmaps'],
    );
  }
}

class ShortcutButton {
  final IconData icon;
  final String label;
  final String message;
  final Color color;

  ShortcutButton({
    required this.icon,
    required this.label,
    required this.message,
    required this.color,
  });
}
