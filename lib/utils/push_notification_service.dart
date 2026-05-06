import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uconnect/config/static.dart';


class PushNotificationService {
  static FirebaseMessaging? _fcm;

  static Future initialise() async {
    if (_fcm == null) {
      _fcm = FirebaseMessaging.instance;
    }

    _fcm!.requestPermission();

  //  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // bool isEnabled = await UserRepository.isNotificationEnabled();
    // String username = await UserRepository.getUsername();
    bool isEnabled = true;
    //String username = await StaticVarMethod.pref_static!.getString('email')!;

    String username = StaticVarMethod.username;
   // String str = "#@F&L^&%U##T#T@#ER###CA@#@M*(PU@&#S%^%2324@*(^&";

   // String username =  StaticVarMethod.notificationToken;
    username = username.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    print("📱 Username para topic: $username"); //Output: FLUTTERCAMPUS2324
    //String username = "shoaib1234";

    if (username.isEmpty) {
      print("⚠️ Username vazio, não será possível subscrever ao topic");
      return;
    }

    if (isEnabled) {
      _fcm!.subscribeToTopic(username).then((_) {
        print("✅ Subscribed to topic: $username");
      }).catchError((e) {
        print("❌ Erro ao subscrever ao topic: $e");
      });
    } else {
      _fcm!.unsubscribeFromTopic(username).then((_) {
        print("✅ Unsubscribed from topic: $username");
      }).catchError((e) {
        print("❌ Erro ao cancelar subscrição do topic: $e");
      });
    }
  }
}
