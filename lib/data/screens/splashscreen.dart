import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uconnect/config/static.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/screens/signinwithbackground1.dart';
import 'package:uconnect/data/screens/signinwithbackground2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/mvvm/view_model/objects.dart';
import '../../bottom_navigation/bottom_navigation_01.dart';
import '../model/loginModel.dart';
import 'package:uconnect/ui/widgets/one_nova_era_logo.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  SharedPreferences? prefs;
  
  // Controllers de animação
  late AnimationController _logoScaleController;
  late AnimationController _glowController;
  late AnimationController _progressController;
  late AnimationController _phraseController;
  
  // Animações
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;
  
  // Progresso
  Timer? _progressTimer;
  
  // Carregamento de veículos
  bool _vehiclesLoaded = false;
  
  // Frases
  final List<String> _phrases = [
    "Estamos preparando seu app...",
    "Tudo pronto para rastrear!",
    "Carregando sua experiência...",
    "Conectando você ao futuro...",
    "Sua frota em suas mãos...",
  ];
  int _currentPhraseIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
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
    
    // Configurar animação de progresso
    _progressController = AnimationController(
      duration: Duration(seconds: 10),
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
    
    // Iniciar sequência de animação
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Iniciar animação da logo
    _logoScaleController.forward();
    
    // Iniciar progresso após logo aparecer
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      _progressController.forward();
      _startProgressTracking();
      _startPhraseRotation();
      
      // Iniciar carregamento de veículos em segundo plano (se usuário estiver logado)
      _loadVehiclesInBackground();
    }
    
    // Aguardar progresso completar e então iniciar lógica
    await Future.delayed(Duration(seconds: 10));
    if (mounted) {
      checkPreference();
    }
  }
  
  Future<void> _loadVehiclesInBackground() async {
    try {
      // Aguardar um pouco para garantir que o contexto está disponível
      await Future.delayed(Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Verificar se há usuário logado antes de carregar veículos
      final prefsInstance = await SharedPreferences.getInstance();
      final userApiHash = prefsInstance.getString('user_api_hash');
      
      if (userApiHash == null || userApiHash.isEmpty) {
        print('⚠️ Usuário não logado, pulando carregamento de veículos');
        return;
      }
      
      print('🔄 Carregando veículos em segundo plano na splash screen...');
      
      if (!mounted) return;
      
      // Obter ObjectStore do Provider
      final objectStore = Provider.of<ObjectStore>(context, listen: false);
      
      // Carregar veículos
      await objectStore.getObjects();
      
      if (mounted) {
        setState(() {
          _vehiclesLoaded = true;
        });
        print('✅ Veículos carregados na splash screen: ${objectStore.objects.length}');
      }
    } catch (e) {
      print('❌ Erro ao carregar veículos na splash screen: $e');
      if (mounted) {
        setState(() {
          _vehiclesLoaded = true; // Mesmo com erro, continuar
        });
      }
    }
  }
  
  void _startProgressTracking() {
    _progressTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
      }
    });
  }
  
  void _startPhraseRotation() {
    Timer.periodic(Duration(milliseconds: 2500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _phraseController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
          });
          _phraseController.reverse();
        }
      });
      
      // Parar após 10 segundos
      if (timer.tick * 2500 >= 10000) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _logoScaleController.dispose();
    _glowController.dispose();
    _progressController.dispose();
    _phraseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = Provider.of<ColorProvider>(context, listen: false);
    // Cor azul padrão para splash screen
    const Color defaultBlueColor = Color(0xFF3b82f6);
    // Usar cor personalizada apenas se o usuário tiver configurado (verificar se secondaryColor é diferente do padrão cinza)
    final Color defaultSecondaryColor = const Color(0xFF6b7280); // Cinza padrão do ColorProvider
    final secondaryColor = (colorProvider.secondaryColor.value != defaultSecondaryColor.value)
        ? colorProvider.secondaryColor 
        : defaultBlueColor;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Mudado para light porque o fundo será escuro
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
                                    // Sombra branca brilhante externa
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
                                    // Sombra branca interna
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
                              
                              // Logo personalizada ou nova imagem padrão com scale e animação
                              Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: Consumer<AppSettingsProvider>(
                                  builder: (context, settingsProvider, child) {
                                    // 1ª Prioridade: Logo personalizada se existir
                                    if (settingsProvider.customSplashLogo != null && 
                                        settingsProvider.customSplashLogo!.existsSync()) {
                                      return Image.file(
                                        settingsProvider.customSplashLogo!,
                                        width: 280,
                                        height: 140,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Em caso de erro, usar nova imagem padrão
                                          return _buildDefaultSplashLogo();
                                        },
                                      );
                                    }
                                    // 2ª Prioridade: Nova imagem padrão
                                    return _buildDefaultSplashLogo();
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      
                      SizedBox(height: 60),
                      
                      // Barra de progresso
                      Container(
                        width: 280,
                        child: Column(
                          children: [
                            AnimatedBuilder(
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
                            
                            SizedBox(height: 24),
                            
                            // Frases cinematográficas
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
                                _phrases[_currentPhraseIndex],
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

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs!.get('baseurlall') != null) {
      StaticVarMethod.baseurlall = prefs!.get('baseurlall').toString();
    } else {
      StaticVarMethod.baseurlall = "http://173.249.6.87";
    }

    if (prefs!.get('email') != null) {
      if (prefs!.get("popup_notify") == null) {
        prefs!.setBool("popup_notify", true);
      }
      checkLogin();
    } else {
      prefs!.setBool("popup_notify", true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => (StaticVarMethod.signinpage == 1)
              ? signinwithbackground1()
              : signinwithbackground2(),
        ),
      );
    }
  }

  void checkLogin() {
    gpsapis api = gpsapis();

    api
        .getlogin(prefs!.get('email').toString(),
            prefs!.get('password').toString())
        .then((response) async {
      if (response.statusCode == 200) {
        prefs!.setBool("popup_notify", true);
        prefs!.setString("user", response.body);

        final res = LoginModel.fromJson(json.decode(response.body));
        StaticVarMethod.user_api_hash = res.userApiHash;
        prefs!.setString('user_api_hash', res.userApiHash!);
        
        // Buscar e salvar dados completos do usuário após login automático
        try {
          final userData = await gpsapis.getUserData();
          if (userData != null) {
            final userJson = json.encode(userData.toJson());
            await prefs!.setString('user_data', userJson);
            print('Dados do usuário salvos no splash: group_id=${userData.group_id}, plan=${userData.plan}');
          }
        } catch (e) {
          print('Erro ao buscar dados do usuário no splash: $e');
        }

        // Enviar token FCM ao servidor após login automático
        if (StaticVarMethod.notificationToken.isNotEmpty) {
          try {
            final fcmResponse = await gpsapis.activateFCM(StaticVarMethod.notificationToken);
            if (fcmResponse.statusCode == 200 || fcmResponse.statusCode == 201) {
              print("✅ Token FCM enviado ao servidor após login automático");
            } else {
              print("⚠️ Erro ao enviar token FCM após login automático: ${fcmResponse.statusCode}");
            }
          } catch (e) {
            print("❌ Erro ao enviar token FCM após login automático: $e");
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavigation_01()),
        );
      } else {
        _irParaLogin();
      }
    }).catchError((error) {
      _irParaLogin();
    });
  }

  void _irParaLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => (StaticVarMethod.signinpage == 1)
            ? signinwithbackground1()
            : signinwithbackground2(),
      ),
    );
  }


  // Widget para logo padrão (nova imagem)
  Widget _buildDefaultSplashLogo() {
    return Image.asset(
      'assets/appsicon/IMG-20260102-WA0018__1_-removebg-preview (1).png',
      width: 280,
      height: 140,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para OneNovaEraLogo se a imagem não existir
        return OneNovaEraLogo(
          width: 280,
          height: 140,
          useCustomStyle: false,
        );
      },
    );
  }

}
