import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/model/loginModel.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:uconnect/utils/hash_values_fix.dart' as hash_fix;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform, PlatformDispatcher;
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:uconnect/data/screens/testscreens/livelocation.dart';
import 'package:uconnect/provider/theme_changer_provider.dart';
import 'package:uconnect/provider/color_provider.dart';
import 'package:uconnect/provider/logo_provider.dart';
import 'package:uconnect/provider/app_settings_provider.dart';
import 'package:uconnect/utils/LocalNotificationService.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/Demo_Localization.dart';
import 'config/Session.dart';
import 'config/static.dart';
import 'data/screens/splashscreen.dart';
import 'mvvm/view_model/objects.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:uconnect/data/screens/map/controllers/map_controller.dart';
import 'package:uconnect/data/screens/signinwithbackground2.dart';
import 'package:uconnect/data/datasources.dart';
import 'package:uconnect/data/gpsserver/datasources.dart' as gpsapis_server;
import 'storage/user_repository.dart';
import '../../bottom_navigation/bottom_navigation_01.dart';
import 'package:uconnect/utils/push_notification_service.dart';
import 'package:uconnect/utils/app_protection_service.dart';
import 'package:uconnect/services/background_service.dart';
import 'package:uconnect/data/services/chat_notification_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uconnect/utils/responsive_helper.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📨 Mensagem FCM recebida (app em background/terminado)");
  print("   Título: ${message.notification?.title ?? message.data['title'] ?? 'N/A'}");
  print("   Corpo: ${message.notification?.body ?? message.data['body'] ?? 'N/A'}");
  print("   Data: ${message.data}");
  
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  LocalNotificationService.display(message);
}

void main() async {
  // Configurar tratamento de erros global
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Tratamento de erros assíncronos
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error');
    print('Stack trace: $stack');
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Inicializar proteção contra cópia/plágio
  try {
    final protectionService = AppProtectionService();
    await protectionService.initializeProtection();
    print('✅ Proteção do app inicializada');
  } catch (e) {
    print('⚠️ Erro ao inicializar proteção: $e');
    // Continue mesmo se a proteção falhar
  }

  // 🔄 Inicializar serviço de background
  try {
    // await BackgroundService.initialize(); // Temporariamente desabilitado devido a problemas de compatibilidade
    print('✅ Serviço de background inicializado');
  } catch (e) {
    print('⚠️ Erro ao inicializar serviço de background: $e');
  }

  try {
    // Verificar se a plataforma é suportada antes de inicializar Firebase
    if (defaultTargetPlatform == TargetPlatform.android || 
        defaultTargetPlatform == TargetPlatform.iOS ||
        kIsWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      print('Firebase initialized successfully');
    } else {
      print('Firebase not configured for platform: $defaultTargetPlatform');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Continue even if Firebase fails
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    UserRepository.prefs = await SharedPreferences.getInstance();
  } catch (e) {
    print('Error initializing SharedPreferences: $e');
  }

  // Inicializar serviço de notificações do chat
  try {
    await ChatNotificationService().initialize();
    print('✅ ChatNotificationService inicializado');
  } catch (e) {
    print('⚠️ Erro ao inicializar ChatNotificationService: $e');
  }

  runApp(const MyHomePage(title: "title"));
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyHomePageState state =
        context.findAncestorStateOfType<_MyHomePageState>()!;
    state.setLocale(newLocale);
  }

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();

    checkPreference();
    
    // 🔧 Inicializar serviços após o primeiro frame para garantir que o context está disponível
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          LocalNotificationService.initialize(context);
        } catch (e) {
          print('Error initializing LocalNotificationService: $e');
        }
        
        try {
          PushNotificationService.initialise();
        } catch (e) {
          print('Error initializing PushNotificationService: $e');
        }

        try {
          getDeviceTokenToSendNotification();
        } catch (e) {
          print('Error getting device token: $e');
        }

        try {
          FirebaseMessaging.instance.requestPermission().then((settings) {
            if (settings.authorizationStatus == AuthorizationStatus.authorized) {
              print('User granted permission');
            } else if (settings.authorizationStatus ==
                AuthorizationStatus.provisional) {
              print('User granted provisional permission');
            } else {
              print('User declined or has not accepted permission');
            }
          });
        } catch (e) {
          print('Error requesting Firebase permission: $e');
        }

        // 🔧 Navigator.of(context) só é seguro após o 1º frame
        try {
          FirebaseMessaging.instance.getInitialMessage().then((message) {
            if (message != null && mounted) {
              final routeFromMessage = message.data["route"];
              if (routeFromMessage != null && mounted) {
                Navigator.of(context).pushNamed(routeFromMessage);
              }
            }
          });
        } catch (e) {
          print('Error getting initial message: $e');
        }

        try {
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print("📨 Mensagem FCM recebida (app em foreground)");
            print("   Título: ${message.notification?.title ?? message.data['title'] ?? 'N/A'}");
            print("   Corpo: ${message.notification?.body ?? message.data['body'] ?? 'N/A'}");
            print("   Data: ${message.data}");
            LocalNotificationService.display(message);
          });
        } catch (e) {
          print('Error setting up onMessage listener: $e');
        }

        try {
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
            if (mounted) {
              final routeFromMessage = message.data["route"];
              if (routeFromMessage != null && mounted) {
                Navigator.of(context).pushNamed(routeFromMessage);
              }
            }
          });
        } catch (e) {
          print('Error setting up onMessageOpenedApp listener: $e');
        }

        // 🔔 Listener para quando o token FCM for atualizado
        try {
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
            print("🔄 Novo token FCM recebido: $newToken");
            StaticVarMethod.notificationToken = newToken;
            
            // Enviar novo token ao servidor se houver user_api_hash
            if (StaticVarMethod.user_api_hash != null && 
                StaticVarMethod.user_api_hash!.isNotEmpty) {
              gpsapis_server.gpsapis.activateFCM(newToken).then((response) {
                if (response.statusCode == 200 || response.statusCode == 201) {
                  print("✅ Novo token FCM enviado com sucesso ao servidor");
                } else {
                  print("⚠️ Erro ao enviar novo token FCM: ${response.statusCode}");
                }
              }).catchError((e) {
                print("❌ Erro ao enviar novo token FCM: $e");
              });
            }
          });
        } catch (e) {
          print('Error setting up onTokenRefresh listener: $e');
        }
      }
    });
  }

  void checkPreference() async {
    StaticVarMethod.pref_static = await SharedPreferences.getInstance();
    StaticVarMethod.baseurlall = "https://web.unnicatelemetria.com.br";

    // 🔐 Recupera user_api_hash salvo do login
    String? hash = StaticVarMethod.pref_static?.getString('user_api_hash');
    StaticVarMethod.user_api_hash = hash ?? "";

    print(
        "🔐 user_api_hash carregado no main: ${StaticVarMethod.user_api_hash}");
  }

  Future<void> getDeviceTokenToSendNotification() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        StaticVarMethod.notificationToken = fcmToken;
        print("📱 FCM TOKEN obtido: ${StaticVarMethod.notificationToken}");
        
        // Enviar token ao servidor se houver user_api_hash
        if (StaticVarMethod.user_api_hash != null && 
            StaticVarMethod.user_api_hash!.isNotEmpty) {
          try {
            final response = await gpsapis_server.gpsapis.activateFCM(fcmToken);
            if (response.statusCode == 200 || response.statusCode == 201) {
              print("✅ Token FCM enviado com sucesso ao servidor");
            } else {
              print("⚠️ Erro ao enviar token FCM: ${response.statusCode} - ${response.body}");
            }
          } catch (e) {
            print("❌ Erro ao enviar token FCM ao servidor: $e");
          }
        } else {
          print("⚠️ user_api_hash não disponível, token não será enviado ainda");
        }
      } else {
        print("⚠️ FCM Token não disponível");
      }
    } catch (e) {
      print("❌ Erro ao obter FCM Token: $e");
    }
  }

  setLocale(Locale locale) {
    if (mounted) {
      setState(() {
        _locale = locale;
      });
    }
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      if (mounted) {
        setState(() {
          _locale = locale;
        });
      }
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => theme_changer_provider()),
        ChangeNotifierProvider(create: (_) => ObjectStore()),
        // ColorProvider para gerenciar cores personalizadas
        ChangeNotifierProvider(
          create: (_) => ColorProvider()..syncColorsFromServer(),
          lazy: false, // Inicializar imediatamente
        ),
        // LogoProvider para gerenciar logos personalizados
        ChangeNotifierProvider(
          create: (_) => LogoProvider()..syncLogosFromServer(),
          lazy: false, // Inicializar imediatamente
        ),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider<MapController>(create: (_) => MapController()),
      ],
      child: Builder(
        builder: (context) {
          final themeChanger = Provider.of<theme_changer_provider>(context);
          return Consumer<ColorProvider>(
            builder: (context, colorProvider, child) {
              return MaterialApp(
                locale: _locale,
                supportedLocales: const [
                  Locale("pt", "pt_BR"), // Português como primeiro (padrão)
                  Locale("en", "GB"), // Inglês Britânico
                  Locale("es", "ES"),
                ],
                localizationsDelegates: const [
                  DemoLocalization.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                localeResolutionCallback: (locale, supportedLocales) {
                  for (var supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale?.languageCode &&
                        supportedLocale.countryCode == locale?.countryCode) {
                      return supportedLocale;
                    }
                  }
                  // Retornar português como padrão quando não houver correspondência
                  return const Locale("pt", "pt_BR");
                },
                debugShowCheckedModeBanner: false,
                // Otimizações para dispositivos fracos
                builder: (context, child) {
                  // Usar colorProvider do Consumer pai
                  return Theme(
                    data: Theme.of(context).copyWith(
                      primaryColor: colorProvider.primaryColor,
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: colorProvider.primaryColor,
                        secondary: colorProvider.secondaryColor,
                      ),
                    ),
                    child: EasyLoading.init()(
                      context,
                      // Inicializar responsividade com ScreenUtil
                      ResponsiveHelper.init(
                      context,
                      MediaQuery(
                        // Desabilitar animações em dispositivos fracos (opcional)
                        data: MediaQuery.of(context).copyWith(
                          textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                        ),
                        child: child ?? const SizedBox(),
                        ),
                      ),
                    ),
                  );
                },
            theme: ThemeData(
              useMaterial3: false,
              scaffoldBackgroundColor: Color(0xFFF9F9F9),
              // Otimizações de performance
              pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Color(0xFFF9F9F9),
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                iconTheme: IconThemeData(color: Colors.black),
              ),
              cardTheme: CardThemeData(
                surfaceTintColor: Colors.white,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            home: SplashScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
