import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/ui/unnica_bot/unnica_bot_chat.dart';
import 'package:uconnect/ui/unnica_bot/unnica_bot_service.dart';

/// Widget que adiciona o botão flutuante do chat em qualquer tela
class GlobalChatButton extends StatelessWidget {
  final Widget child;

  const GlobalChatButton({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// Verifica se a rota atual é uma página de login ou boas-vindas
  bool _shouldHideChatButton(BuildContext context) {
    try {
      // Verificar se não há token de autenticação válido
      final token = StaticVarMethod.user_api_hash;
      final defaultToken = "\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G";
      
      if (token == null || token.isEmpty || token == defaultToken) {
        return true;
      }
      
      // Verificar o tipo do widget filho
      final childType = child.runtimeType.toString();
      
      // Lista de tipos de widgets que devem esconder o chat
      final hideChatWidgets = [
        'signinwithbackground1',
        'signinwithbackground2',
        'LoginWelcomeScreen',
        'SplashScreen',
      ];
      
      for (final widgetType in hideChatWidgets) {
        if (childType.contains(widgetType)) {
          return true;
        }
      }
      
      // Verificar também pela rota atual
      final route = ModalRoute.of(context);
      if (route != null) {
        final routeName = route.settings.name ?? '';
        if (routeName.toLowerCase().contains('login') || 
            routeName.toLowerCase().contains('signin') || 
            routeName.toLowerCase().contains('welcome') ||
            routeName.toLowerCase().contains('splash')) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Erro ao verificar se deve esconder chat: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se deve esconder o botão
    final shouldHide = _shouldHideChatButton(context);
    
    if (shouldHide) {
      return child;
    }
    
    // Usar Stack para sobrepor o botão em qualquer tela
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          bottom: 80,
          right: 16,
          child: _ChatFloatingButton(),
        ),
      ],
    );
  }
}

class _ChatFloatingButton extends StatefulWidget {
  @override
  State<_ChatFloatingButton> createState() => _ChatFloatingButtonState();
}

class _ChatFloatingButtonState extends State<_ChatFloatingButton> {
  bool _isChatOpen = false;

  /// Obtém o token válido do app
  Future<String?> _getValidToken() async {
    final defaultToken = "\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G";
    
    // 1. Tentar obter do StaticVarMethod
    String? token = StaticVarMethod.user_api_hash;
    
    if (token != null && token.isNotEmpty && token != defaultToken) {
      return token;
    }
    
    // 2. Tentar carregar do SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('user_api_hash');
      
      if (savedToken != null && savedToken.isNotEmpty && savedToken != defaultToken) {
        StaticVarMethod.user_api_hash = savedToken;
        return savedToken;
      }
    } catch (e) {
      print('⚠️ Erro ao carregar token do SharedPreferences: $e');
    }
    
    return null;
  }

  void _openChat() async {
    if (_isChatOpen) {
      return;
    }
    
    if (!mounted) {
      return;
    }
    
    setState(() {
      _isChatOpen = true;
    });

    try {
      final token = await _getValidToken();
      
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Faça login no app principal para usar o chat.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Obter status do bot
      final service = UnnicaBotService(token: token);
      BotStatus? status;
      try {
        status = await service.getStatus();
      } catch (e) {
        print('⚠️ Erro ao verificar status: $e');
      }

      if (!mounted) return;

      // Verificar se há Navigator disponível
      final navigator = Navigator.maybeOf(context, rootNavigator: false);
      
      if (navigator != null) {
        try {
          await navigator.push(
            MaterialPageRoute(
              builder: (BuildContext context) => UnnicaBotChatScreen(
                token: token,
                status: status,
              ),
            ),
          );
        } catch (e) {
          print('⚠️ Erro ao usar Navigator padrão, tentando rootNavigator...');
          if (!mounted) return;
          
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (BuildContext context) => UnnicaBotChatScreen(
                token: token,
                status: status,
              ),
            ),
          );
        }
      } else {
        if (!mounted) return;
        
        await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (BuildContext context) => UnnicaBotChatScreen(
              token: token,
              status: status,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao abrir chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir chat: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChatOpen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ColorProvider>(
      builder: (context, colorProvider, child) {
        final primaryColor = colorProvider.primaryColor ?? Colors.blue;
        
        return FloatingActionButton(
          onPressed: _isChatOpen ? () {} : _openChat,
          backgroundColor: primaryColor,
          child: Stack(
            children: [
              Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 28,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
            ],
          ),
          tooltip: 'Abrir UnnicaBot',
        );
      },
    );
  }
}

