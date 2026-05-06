import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import 'package:uconnect/bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/utils/translation_helper.dart';

class LoginWelcomeScreen extends StatefulWidget {
  @override
  _LoginWelcomeScreenState createState() => _LoginWelcomeScreenState();
}

class _LoginWelcomeScreenState extends State<LoginWelcomeScreen> with TickerProviderStateMixin {
  SharedPreferences? prefs;
  
  // Controllers de animação
  late AnimationController _logoScaleController;
  late AnimationController _glowController;
  late AnimationController _progressController;
  late AnimationController _textController;
  
  // Animações
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _textOpacityAnimation;
  
  // Dados do usuário
  String? _userFirstName;
  bool _vehiclesLoaded = false;
  bool _loadingComplete = false;
  
  // Obter frase com nome do usuário na primeira frase
  String _getPhrase(int index) {
    if (index == 0 && _userFirstName != null) {
      return TranslationHelper.translateSync(context, 'Seja bem vindo(a), $_userFirstName!', 'Welcome, $_userFirstName!');
    }
    final phrases = [
      TranslationHelper.translateSync(context, 'Seja bem vindo(a)', 'Welcome'),
      TranslationHelper.translateSync(context, 'Estamos muito feliz de ter você aqui conosco!', 'We are very happy to have you here with us!'),
      TranslationHelper.translateSync(context, 'Estamos configurando o seu app', 'We are setting up your app'),
    ];
    if (index >= 0 && index < phrases.length) {
      return phrases[index];
    }
    return phrases[0];
  }
  int _currentPhraseIndex = 0;
  late AnimationController _phraseController;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Configurar controller de animação da logo (scale)
    _logoScaleController = AnimationController(
      duration: Duration(milliseconds: 1800),
      vsync: this,
    );
    
    // Configurar animação de glow pulsante
    _glowController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Configurar animação de progresso (5 segundos)
    _progressController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );
    
    // Configurar animação de texto
    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Configurar animação de frases
    _phraseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Configurar animações
    _logoScaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoScaleController,
      curve: Curves.easeOutBack,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    // Iniciar sequência de animação
    _startAnimationSequence();
  }
  
  void _startPhraseRotation() {
    Timer.periodic(Duration(milliseconds: 2000), (timer) {
      if (!mounted || _loadingComplete) {
        timer.cancel();
        return;
      }
      
      _phraseController.forward(from: 0.0).then((_) {
        if (mounted && !_loadingComplete) {
          setState(() {
            _currentPhraseIndex = (_currentPhraseIndex + 1) % 3; // 3 frases de boas-vindas
          });
          _phraseController.reverse();
        }
      });
    });
  }

  Future<void> _loadUserData() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final userString = prefs!.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final client = userData['user']['client'];
        setState(() {
          _userFirstName = client['first_name'] ?? TranslationHelper.translateSync(context, 'Usuário', 'User');
        });
      }
    } catch (e) {
      print('Erro ao carregar dados do usuário: $e');
      setState(() {
        _userFirstName = TranslationHelper.translateSync(context, 'Usuário', 'User');
      });
    }
  }

  void _startAnimationSequence() async {
    // Iniciar animação da logo
    _logoScaleController.forward();
    
    // Aguardar logo aparecer e então mostrar texto
    await Future.delayed(Duration(milliseconds: 800));
    if (mounted) {
      _textController.forward();
      // Iniciar rotação de frases
      _startPhraseRotation();
    }
    
    // Iniciar progresso e carregar veículos em segundo plano
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      _progressController.forward();
      _loadVehiclesInBackground();
    }
    
    // Aguardar progresso completar (5 segundos) ou até veículos carregarem
    int waitTime = 0;
    while (waitTime < 5000 && !_vehiclesLoaded && mounted) {
      await Future.delayed(Duration(milliseconds: 100));
      waitTime += 100;
    }
    
    // Garantir pelo menos 5 segundos de exibição da mensagem
    if (waitTime < 5000) {
      await Future.delayed(Duration(milliseconds: 5000 - waitTime));
    }
    
    if (mounted) {
      _loadingComplete = true;
      _navigateToMainScreen();
    }
  }
  
  Future<void> _loadVehiclesInBackground() async {
    try {
      print('🔄 Carregando veículos em segundo plano...');
      
      // Usar WidgetsBinding para garantir que o contexto está disponível
      await Future.delayed(Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      final objectStore = Provider.of<ObjectStore>(context, listen: false);
      
      // Carregar veículos
      await objectStore.getObjects();
      
      if (mounted) {
        setState(() {
          _vehiclesLoaded = true;
        });
        print('✅ Veículos carregados: ${objectStore.objects.length}');
      }
    } catch (e) {
      print('❌ Erro ao carregar veículos: $e');
      if (mounted) {
        setState(() {
          _vehiclesLoaded = true; // Mesmo com erro, continuar
        });
      }
    }
  }
  
  void _navigateToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavigation_01()),
    );
  }

  @override
  void dispose() {
    _logoScaleController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _textController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    // Cor azul padrão para tela de welcome
    const Color defaultBlueColor = Color(0xFF3b82f6);
    // Usar cor personalizada apenas se o usuário tiver configurado
    const Color defaultSecondaryColor = Color(0xFF6b7280); // Cinza padrão do ColorProvider
    final secondaryColor = (colorProvider.secondaryColor.value != defaultSecondaryColor.value)
        ? colorProvider.secondaryColor 
        : defaultBlueColor;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Consumer<AppSettingsProvider>(
          builder: (context, settingsProvider, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondaryColor,
                    secondaryColor.withOpacity(0.8),
                    secondaryColor.withOpacity(0.9),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Conteúdo principal
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo com animações
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _logoScaleController,
                            _glowController,
                          ]),
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Efeito branco brilhante pulsante ao redor da logo
                                Container(
                                  width: 220 * _logoScaleAnimation.value * _glowAnimation.value,
                                  height: 220 * _logoScaleAnimation.value * _glowAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.6 * _glowAnimation.value),
                                        blurRadius: 50 * _glowAnimation.value,
                                        spreadRadius: 15 * _glowAnimation.value,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: 80,
                                        spreadRadius: 25,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                // Glow pulsante adicional
                                Container(
                                  width: 200 * _logoScaleAnimation.value * _glowAnimation.value,
                                  height: 200 * _logoScaleAnimation.value * _glowAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5 * (2 - _glowAnimation.value)),
                                        blurRadius: 40 * _glowAnimation.value,
                                        spreadRadius: 10 * _glowAnimation.value,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Logo com scale e borda branca brilhante
                                Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.8),
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 40,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: _buildAnimatedLogo(settingsProvider),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        
                        SizedBox(height: 60),
                        
                        // Barra de progresso (acima das frases)
                        Container(
                          width: 280,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Stack(
                                  children: [
                                    // Fundo
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    // Progresso em branco
                                    FractionallySizedBox(
                                      widthFactor: _progressAnimation.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.white.withOpacity(0.9),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.6),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Mensagens de boas-vindas (abaixo da barra)
                        AnimatedBuilder(
                          animation: Listenable.merge([_textController, _phraseController]),
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textOpacityAnimation.value,
                              child: Column(
                                children: [
                                  // Frases rotativas (uma por vez) - nome do usuário só na primeira
                                  AnimatedSwitcher(
                                    duration: Duration(milliseconds: 800),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset(0, 0.3),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOut,
                                          )),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      _getPhrase(_currentPhraseIndex),
                                      key: ValueKey(_currentPhraseIndex),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        fontFamily: 'Roboto',
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(AppSettingsProvider settingsProvider) {
    // 1ª Prioridade: Logo do splash screen personalizada se existir
    final customSplashLogo = settingsProvider.customSplashLogo;
    if (customSplashLogo != null && customSplashLogo.existsSync()) {
      return ClipOval(
        child: Image.file(
          customSplashLogo,
          width: 150,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultLogo();
          },
        ),
      );
    } else {
      // 2ª Prioridade: Nova imagem padrão
      return _buildDefaultLogo();
    }
  }

  Widget _buildDefaultLogo() {
    try {
      return ClipOval(
        child: Image.asset(
          'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback para logo antiga se a nova não existir
            return ClipOval(
              child: Image.asset(
                'assets/appsicon/logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.grey.shade600,
                      size: 80,
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
        ),
        child: Icon(
          Icons.location_on,
          color: Colors.grey.shade600,
          size: 80,
        ),
      );
    }
  }
}

