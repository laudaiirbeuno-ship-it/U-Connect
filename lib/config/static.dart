import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:maktrogps/data/model/devices.dart';
import 'package:maktrogps/data/model/events.dart';
import 'package:maktrogps/data/model/history.dart';
import 'package:maktrogps/storage/user_repository.dart';
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

  static int reportType = 1;

  //static String baseurlall= "https://maktrogps.com";

  // static String baseurlall= "http://38.242.199.100";
  // static String baseurlall= "http://38.242.158.64";

  // static String baseurlall= "http://207.244.225.51";

  //static String baseurlall= "http://136.244.82.204";
  //demo@demo.com   demo
  // static String baseurlall="https://bittrackerz.com";
  //static String baseurlall= "http://gps.mototrackerbd.com";
  //static String baseurlall= "http://brtcvts.com";
  static String baseurlall = UserRepository.getServerURL();
  // static String imageurl= 'assets/appsicon/trackon.png';

  // static String listimageurl= 'assets/appsicon/rqtrackerlist.png';
  // static String loginimageurl= 'assets/appsicon/rqtrackerlogin.png';
  // static String splashimageurl= 'assets/appsicon/rqtrackerlogin.png';

  // static String listimageurl= 'assets/appsicon/trackmasterlistscreen.jpeg';
  // static String loginimageurl= 'assets/appsicon/trackmasterlogin.jpeg';
  // static String splashimageurl= 'assets/appsicon/trackmasterlogin.jpeg';

  // static String listimageurl= 'assets/appsicon/sigo500by200.png';
  // static String loginimageurl= 'assets/appsicon/sigo500by200.png';
  // static String splashimageurl= 'assets/appsicon/sigo500by200.png';
  //static String listimageurl= 'assets/appsicon/vehitrack.jpeg';
  //static String loginimageurl= 'assets/appsicon/vehitrack.jpeg';
  //static String splashimageurl= 'assets/appsicon/vehitrack.jpeg';
  //
  // static String listimageurl= 'assets/appsicon/gblrentalexpressappicon.jpg';
  // static String loginimageurl= 'assets/appsicon/gblrentalexpressappicon.jpg';
  // static String splashimageurl= 'assets/appsicon/gblrentalexpressappicon.jpg';

  // static String listimageurl= 'assets/appsicon/vtracklogo.jpeg';
  // static String loginimageurl= 'assets/appsicon/vtracklogo.jpeg';
  // static String splashimageurl= 'assets/appsicon/vtracklogo.jpeg';

  // //
  // static String listimageurl= 'assets/appsicon/navaiotfull512by512.png';
  // static String loginimageurl= 'assets/appsicon/navaiotfull512by512.png';
  // static String splashimageurl= 'assets/appsicon/navaiotfull512by512.png';
  //
  // static String listimageurl= 'assets/appsicon/orbitgps.jpeg';
  // static String loginimageurl= 'assets/appsicon/orbitgps.jpeg';
  // static String splashimageurl= 'assets/appsicon/orbitgps.jpeg';

  // static String listimageurl= 'assets/appsicon/expresstrqarfinal.png';
  // static String loginimageurl= 'assets/appsicon/expresstrqarfinal.png';
  // static String splashimageurl= 'assets/appsicon/expresstrqarfinal.png';

  // static String listimageurl= 'assets/appsicon/telematix.png';
  // static String loginimageurl= 'assets/appsicon/telematix.png';
  // static String splashimageurl= 'assets/appsicon/telematix.png';

  static String listimageurl = 'assets/appsicon/logo-fill.png';
  static String loginimageurl = 'assets/appsicon/logo.png';
  static String splashimageurl = 'assets/appsicon/logo-fill.png';

  // static String listimageurl= 'assets/appsicon/sigo500by200.png';
  // static String loginimageurl= 'assets/appsicon/sigo500by200.png';
  // static String splashimageurl= 'assets/appsicon/sigo500by200.png';

  // static String listimageurl= 'assets/appsicon/roadpoint.jpeg';
  // static String loginimageurl= 'assets/appsicon/roadpoint.jpeg';
  // static String splashimageurl= 'assets/appsicon/roadpoint.jpeg';

  // static String listimageurl= 'assets/appsicon/wonderlevel.jpg';
  // static String loginimageurl= 'assets/appsicon/wonderlevel.jpg';
  // static String splashimageurl= 'assets/appsicon/wonderlevel.jpg';

  // static String listimageurl= 'assets/appsicon/gmtsfiverbangladeshlogo.png';
  // static String loginimageurl= 'assets/appsicon/gmtsfiverbangladeshlogo.png';
  // static String splashimageurl= 'assets/appsicon/gmtsfiverbangladeshlogo.png';

  // static String listimageurl= 'assets/appsicon/smartgpstrackerlist.png';
  // static String loginimageurl= 'assets/appsicon/smartgpstrackerlist.png';
  // static String splashimageurl= 'assets/appsicon/smartgpstrackerlist.png';

  // static String listimageurl= 'assets/appsicon/colombiaservirastreo.jpeg';
  // static String loginimageurl= 'assets/appsicon/colombiaservirastreo.jpeg';
  // static String splashimageurl= 'assets/appsicon/colombiaservirastreo.jpeg';

  //
  // static String listimageurl= 'assets/appsicon/sftech.png';
  // static String loginimageurl= 'assets/appsicon/sftech.png';
  // static String splashimageurl= 'assets/appsicon/sftech.png';
  //
  // static String listimageurl= 'assets/appsicon/btplloginlogo.png';
  // static String loginimageurl= 'assets/appsicon/btplloginlogo.png';
  // static String splashimageurl= 'assets/appsicon/btplloginlogo.png';

  // static String listimageurl= 'assets/appsicon/proativarastreamentoicon.png';
  // static String loginimageurl= 'assets/appsicon/proativarastreamentoicon.png';
  // static String splashimageurl= 'assets/appsicon/proativarastreamentoicon.png';

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
}
