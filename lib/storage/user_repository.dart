import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/config/static.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  static SharedPreferences? prefs;
  static void setServerURL(String lang) {
    prefs!.setString("url", lang);
  }

  static String getServerURL() {
    return "https://web.unnicatelemetria.com.br";
  }
}
