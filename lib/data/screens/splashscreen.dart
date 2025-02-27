import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:maktrogps/bottom_navigation/bottom_navigation.dart';
import 'package:maktrogps/config/static.dart';
import 'package:maktrogps/data/datasources.dart';
import 'package:maktrogps/data/model/Login.dart';
import 'package:maktrogps/data/model/PushNotification.dart';
import 'package:maktrogps/data/screens/signin.dart';
import 'package:maktrogps/data/screens/signinwithbackground1.dart';
import 'package:maktrogps/data/screens/signinwithbackground2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bottom_navigation/bottom_navigation_01.dart';
import '../model/loginModel.dart';
import 'listscreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SharedPreferences? prefs;

  @override
  void initState() {
    checkPreference();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      width: 68,
      height: 68,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            StaticVarMethod.splashimageurl,
            width: 120,
            height: 120,
          )
        ],
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

    api.getlogin(
        prefs!.get('email').toString(), prefs!.get('password').toString())
        .then((response) {
      if (response != null) {
        if (response.statusCode == 200) {
          prefs!.setBool("popup_notify", true);
          prefs!.setString("user", response.body);
          //isBusy = false;
          //isLoggedIn = true;
          final res = LoginModel.fromJson(json.decode(response.body));
          StaticVarMethod.user_api_hash = res.userApiHash;
          // EasyLoading.dismiss();
          prefs!.setString('user_api_hash', res.userApiHash!);
          // updateToken();
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BottomNavigation_01()),
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
}
