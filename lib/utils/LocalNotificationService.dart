import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static void initialize(BuildContext context) {
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: AndroidInitializationSettings("@mipmap/ic_launcher"));

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

      // Obter título e corpo da notificação
      String title = "U-Connect";
      String body = "";

      if (message.notification != null) {
        title = message.notification?.title ?? "U-Connect";
        body = message.notification?.body ?? "";
      } else if (message.data.isNotEmpty) {
        // Se não houver notification, usar dados do payload
        title = message.data["title"] ?? message.data["notification_title"] ?? "U-Connect";
        body = message.data["body"] ?? message.data["notification_body"] ?? message.data["message"] ?? "";
      }

      // Se ainda não houver corpo, tentar usar o primeiro valor do data
      if (body.isEmpty && message.data.isNotEmpty) {
        body = message.data.values.first.toString();
      }

      // Não exibir notificação se não houver conteúdo
      if (body.isEmpty && title == "U-Connect") {
        print("⚠️ Mensagem FCM sem conteúdo de notificação");
        return;
      }

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
        title,
        body,
        notificationDetails,
        payload: message.data["route"] ?? message.data.toString(),
      );

      print("✅ Notificação exibida: $title - $body");
    } on Exception catch (e) {
      print("❌ ERRO ao exibir notificação");
      print(e);
      print("Mensagem recebida: ${message.data}");
    }
  }
}
