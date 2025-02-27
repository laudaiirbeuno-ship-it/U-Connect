import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static void initialize(BuildContext context) {
    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher_round"));

    _notificationsPlugin.initialize(initializationSettings);

    // Criação do canal de notificação
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'GPS_Wox_Channel', // id
      'U-Connect Notifications', // nome
      description: 'Canal para notificações do U-Connect',
      importance: Importance.max,
    );

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void display(RemoteMessage message) async {
    try {
      prefs = await SharedPreferences.getInstance();
      final id = Random().nextInt(9999);
      final channel_id = "GPS_Wox_Channel";

      final NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            channel_id,
            "U-Connect Notifications",
            importance: Importance.max,
            priority: Priority.high,
            // Adicione o ícone da notificação aqui, se necessário
            // smallIcon: '@mipmap/ic_launcher', // ou o ícone que você deseja usar
          ));

      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data["route"],
      );
    } on Exception catch (e) {
      print("ERRO AQUI");
      print(e);
    }
  }
}