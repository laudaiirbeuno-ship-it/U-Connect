import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/data/screens/chat/views/chat_screen.dart';
import 'package:uconnect/utils/translation_helper.dart';
import 'package:uconnect/data/services/internal_chat_service.dart';
import 'dart:async';

/// Botão de chat flutuante padronizado
/// Posição fixa: bottom: 100, right/left: 16
/// Inclui animação de onda, badge de mensagens não lidas e integração com tema
class ChatFloatingButton extends StatefulWidget {
  /// Se true, posiciona o botão à esquerda (útil quando há FloatingActionButton na direita)
  final bool alignLeft;

  const ChatFloatingButton({
    Key? key,
    this.alignLeft = false,
  }) : super(key: key);

  @override
  State<ChatFloatingButton> createState() => _ChatFloatingButtonState();
}

class _ChatFloatingButtonState extends State<ChatFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _waveAnimation2;
  
  final InternalChatService _chatService = InternalChatService();
  int _unreadCount = 0;
  Timer? _pollingTimer;

  // Posição fixa padronizada
  static const double _fixedBottom = 100.0;
  static const double _fixedHorizontal = 16.0;

  @override
  void initState() {
    super.initState();
    
    // Configurar animação de onda (sempre ativa)
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Segunda onda para efeito mais suave
    _waveAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Carregar cor configurada e contagem de mensagens não lidas
    _loadSettings();
    _loadUnreadCount();
    
    // Polling para atualizar badge
    _startPolling();
  }

  Future<void> _loadSettings() async {
    try {
      // Buscar configurações do usuário
      // Como não temos acesso direto às configurações, vamos buscar via getMessages
      // ou criar um método específico. Por enquanto, vamos usar SharedPreferences
      // ou buscar quando necessário no build
    } catch (e) {
      print('Erro ao carregar configurações: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final contacts = await _chatService.getContacts();
      final totalUnread = contacts.fold<int>(
        0,
        (sum, contact) => sum + contact.unread,
      );
      
      if (mounted) {
        setState(() {
          _unreadCount = totalUnread;
        });
      }
    } catch (e) {
      // Silenciosamente falha - não é crítico
      print('Erro ao carregar contagem de mensagens: $e');
    }
  }

  void _startPolling() {
    // Atualizar badge a cada 5 segundos
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _loadUnreadCount();
    });
  }

  void _openChat() async {
    // Parar animação temporariamente
    _animationController.stop();
    
    // Navegar para o chat
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(),
      ),
    );
    
    // Recarregar contagem ao retornar
    _loadUnreadCount();
    
    // Retomar animação
    _animationController.repeat();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getUserSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data ?? {};
            final floatingBtnColor = settings['floating_btn_color'];
            final buttonColor = floatingBtnColor != null
                ? Color(int.parse(floatingBtnColor.replaceFirst('#', '0xff')))
                : colorProvider.primaryColor;
            
            return Positioned(
              bottom: _fixedBottom,
              right: widget.alignLeft ? null : _fixedHorizontal,
              left: widget.alignLeft ? _fixedHorizontal : null,
              child: GestureDetector(
                onTap: _openChat,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Efeito de onda 1 (sempre ativo)
                        Transform.scale(
                          scale: _waveAnimation.value * 0.4 + 1.0,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: buttonColor.withOpacity(0.2 * (1 - _waveAnimation.value)),
                            ),
                          ),
                        ),
                        // Efeito de onda 2 (sempre ativo, com delay)
                        Transform.scale(
                          scale: _waveAnimation2.value * 0.5 + 1.0,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: buttonColor.withOpacity(0.15 * (1 - _waveAnimation2.value)),
                            ),
                          ),
                        ),
                        
                        // Botão principal (sempre com pulso suave)
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: FloatingActionButton(
                            onPressed: _openChat,
                            backgroundColor: buttonColor,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.chat,
                                  color: colorScheme.onPrimary,
                                  size: 28,
                                ),
                                
                                // Badge de mensagens não lidas
                                if (_unreadCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.surface,
                                          width: 2,
                                        ),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Text(
                                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            tooltip: TranslationHelper.translateSync(
                              context,
                              'Chat',
                              'Chat',
                            ),
                            elevation: 6,
                            heroTag: 'chat_floating_button',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserSettings() async {
    try {
      return await _chatService.getSettings();
    } catch (e) {
      print('Erro ao buscar settings: $e');
      return {};
    }
  }
}
