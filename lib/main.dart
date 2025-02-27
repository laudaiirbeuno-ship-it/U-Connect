import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'data/model/loginModel.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:maktrogps/data/screens/testscreens/livelocation.dart';
import 'package:maktrogps/provider/theme_changer_provider.dart';
import 'package:maktrogps/utils/LocalNotificationService.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/Demo_Localization.dart';
import 'config/Session.dart';
import 'config/static.dart';
import 'data/screens/splashscreen.dart';
import 'mvvm/view_model/objects.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maktrogps/data/screens/signinwithbackground1.dart';
import 'package:maktrogps/data/screens/signinwithbackground2.dart';
import 'package:maktrogps/data/datasources.dart';
import 'storage/user_repository.dart';
import '../../bottom_navigation/bottom_navigation_01.dart';

Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.data.toString());
  print(message.notification!.title);
  print("AQUI 2");
  LocalNotificationService.display(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  UserRepository.prefs = await SharedPreferences.getInstance();
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
  void initState() {
    super.initState();
    checkPreference();
    LocalNotificationService.initialize(context);

    // Solicitar permissão para notificações
    // if (Platform.isIOS) {
    //   FirebaseMessaging.instance.requestPermission().then((settings) {
    //     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //       print('User  granted permission');
    //     } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    //       print('User  granted provisional permission');
    //     } else {
    //       print('User  declined or has not accepted permission');
    //     }
    //   });
    // }

    FirebaseMessaging.instance.requestPermission().then((settings) {
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User  granted permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User  granted provisional permission');
      } else {
        print('User  declined or has not accepted permission');
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        final routeFromMessage = message.data["route"];
        Navigator.of(context).pushNamed(routeFromMessage);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print(message.notification!.body);
        print(message.notification!.title);
        LocalNotificationService.display(message); // Adicione esta linha
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final routeFromMessage = message.data["route"];
      Navigator.of(context).pushNamed(routeFromMessage);
    });

    getToken();
  }

  void checkPreference() async {
    StaticVarMethod.pref_static = await SharedPreferences.getInstance();
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
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => (StaticVarMethod.signinpage == 1)
                ? signinwithbackground1()
                : signinwithbackground2()),
      );
    }
  }

  void checkLogin() {
    gpsapis api = new gpsapis();
    api
        .getlogin(
            prefs!.get('email').toString(), prefs!.get('password').toString())
        .then((response) {
      if (response != null) {
        if (response.statusCode == 200) {
          prefs!.setBool("popup_notify", true);
          prefs!.setString("user", response.body);
          final res = LoginModel.fromJson(json.decode(response.body));
          StaticVarMethod.user_api_hash = res.userApiHash;
          prefs!.setString('user_api_hash', res.userApiHash!);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BottomNavigation_01()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => (StaticVarMethod.signinpage == 1)
                    ? signinwithbackground1()
                    : signinwithbackground2()),
          );
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => (StaticVarMethod.signinpage == 1)
                  ? signinwithbackground1()
                  : signinwithbackground2()),
        );
      }
    });
  }

  Future<void> getDeviceTokenToSendNotification() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    StaticVarMethod.notificationToken = fcmToken.toString();
    print("Token Value: " + StaticVarMethod.notificationToken);
  }

  Future<void> getToken() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
  }

  @override
  Widget build(BuildContext context) {
    getDeviceTokenToSendNotification();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => theme_changer_provider()),
        ChangeNotifierProvider(create: (_) => ObjectStore()),
      ],
      child: Builder(builder: (context) {
        final themeChanger = Provider.of<theme_changer_provider>(context);
        return MaterialApp(
          locale: _locale,
          supportedLocales: const [
            Locale("en", "US"),
            Locale("pt", "pt_BR"),
            Locale("es", "ES")
          ],
          localizationsDelegates: const [
            DemoLocalization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale!.languageCode &&
                  supportedLocale.countryCode == locale.countryCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: false,
            scaffoldBackgroundColor: Colors.white,
            cardTheme: const CardTheme(
              surfaceTintColor: Colors.white,
            ),
          ),
          home: signinwithbackground2(),
          builder: EasyLoading.init(),
        );
      }),
    );
  }
}
