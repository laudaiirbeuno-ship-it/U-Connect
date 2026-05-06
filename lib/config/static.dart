import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:uconnect/data/model/devices.dart';
import 'package:uconnect/data/model/events.dart';
import 'package:uconnect/data/model/history.dart';
import 'package:uconnect/storage/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StaticVarMethod {
  static bool isInitLocalNotif = false;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool isDarkMode = false;
  static String? user_api_hash =
      "\$2y\$10\$yUmXjzCeKUZ1fb8SHRZJTe7AWBmVhDAMrSmoi6DVxkicvS3rtmW6G";
  static List<deviceItems> devicelist = [];
  static List<EventsData> eventList = [];
  static String deviceName = "";
  static String username = "";
  static String deviceId = "";
  static String imei = "";
  static String simno = "";
  static String phone_no = "+212664719191";
  static String email = "contact@geoflotte.ma";
  static int notificationCount = 0;

  static int reportType = 1;
  static String? reportName;

  static String baseurlall = UserRepository.getServerURL();
  
  static String listimageurl = 'assets/appsicon/logo-fill.png';
  static String loginimageurl = 'assets/appsicon/logo.png';
  static String splashimageurl = 'assets/appsicon/logo-fill.png';

  static String backgroundimageurl = 'assets/appsicon/smartgpstrackerlogin.png';

  //notification
  static String type = "";
  static String speed = "";
  static String time = "";
  static String message = "";
  static double lat = 0.0;
  static double lng = 0.0;
  static String devicestatus = "Stopped";
  static Color devicestatuscolor = Colors.red;
  static SharedPreferences? pref_static;
  //static String baseurlall= "https://ingreso.securitytecno.com";
  static int signinpage = 2;
  static String notificationToken = "";
  static bool notificationback = true;
  static String reporturl = "";
  static String fromdate = DateFormat('yyyy-MM-dd').format(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
  static String fromtime = "00:00";
  static String todate = DateFormat('yyyy-MM-dd').format(DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day + 1));
  static String totime = DateFormat('HH:mm').format(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      DateTime.now().hour,
      DateTime.now().minute));
  
  // Função para atualizar o contador de notificações não lidas
  static void updateUnreadNotificationCount() {
    notificationCount = eventList.where((event) => !event.read).length;
  }
}
