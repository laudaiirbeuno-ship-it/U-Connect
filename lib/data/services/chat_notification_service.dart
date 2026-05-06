import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';

/// Serviço para gerenciar notificações e som do chat
/// Toca som contínuo até o usuário abrir o chat
class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isChatOpen = false;
  Timer? _panicSoundTimer;

  // Canal de notificação com som
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'chat_notifications',
    'Chat Notifications',
    description: 'Notificações do chat interno com som',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Inicializar o serviço
  Future<void> initialize() async {
    // Configurar Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Criar canal de notificação Android
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Configurar Firebase Messaging
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  /// Handler para notificação tocada
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == 'panic') {
      _stopPanicSound();
    } else {
      _stopSound();
    }
    _isChatOpen = true;
  }

  /// Handler para mensagem em foreground
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      _showNotification(message);
      _playSound();
    }
  }

  /// Handler para mensagem em background
  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat_message') {
      _stopSound();
      _isChatOpen = true;
    }
  }

  /// Tocar som de pânico (contínuo até abrir chat)
  Future<void> _playPanicSound() async {
    if (_isChatOpen) return;

    _isPlaying = true;

    // Tocar som em loop contínuo
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Tentar tocar som personalizado de pânico
      try {
        await _audioPlayer.play(AssetSource('sounds/panic.mp3'));
      } catch (e) {
        // Se não houver arquivo, usar som padrão do sistema
        // O som será tocado pela notificação
        print('⚠️ Arquivo de som de pânico não encontrado, usando som padrão');
      }

      // Verificar periodicamente se o chat foi aberto
      _panicSoundTimer?.cancel();
      _panicSoundTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_isChatOpen) {
          _stopPanicSound();
          timer.cancel();
        }
      });
    } catch (e) {
      print('Erro ao tocar som de pânico: $e');
      _isPlaying = false;
    }
  }

  /// Parar som de pânico
  Future<void> _stopPanicSound() async {
    _panicSoundTimer?.cancel();
    _panicSoundTimer = null;
    await _stopSound();
  }

  /// Mostrar notificação
  Future<void> _showNotification(RemoteMessage message, {bool isPanic = false}) async {
    final title = message.notification?.title ?? 'Nova mensagem';
    final body = message.notification?.body ?? 'Você recebeu uma nova mensagem';

    final androidDetails = AndroidNotificationDetails(
      isPanic ? 'panic_notifications' : 'chat_notifications',
      isPanic ? 'Panic Notifications' : 'Chat Notifications',
      channelDescription: isPanic 
          ? 'Notificações de pânico com som contínuo'
          : 'Notificações do chat interno',
      importance: Importance.max, // Máxima importância para pânico
      priority: Priority.max, // Máxima prioridade para pânico
      showWhen: true,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      color: isPanic ? Colors.red : null,
      ongoing: isPanic, // Notificação contínua para pânico
      autoCancel: !isPanic, // Não cancelar automaticamente se for pânico
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      isPanic 
          ? 999999 // ID fixo para pânico (sempre substitui a anterior)
          : DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: isPanic ? 'panic' : 'chat',
    );
  }

  /// Tocar som contínuo
  Future<void> _playSound() async {
    if (_isPlaying || _isChatOpen) return;

    try {
      _isPlaying = true;
      
      // Configurar loop do som
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Tentar tocar um som personalizado (se houver arquivo)
      // Se não houver, o som padrão do sistema será usado pela notificação
      try {
        // Tentar tocar som de assets (se existir)
        await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
      } catch (e) {
        // Se não houver arquivo, usar som padrão do sistema via notificação
        // O som será tocado automaticamente pela notificação do sistema
        print('⚠️ Arquivo de som não encontrado, usando som padrão do sistema');
      }
      
    } catch (e) {
      print('Erro ao tocar som: $e');
      _isPlaying = false;
    }
  }

  /// Parar som
  Future<void> _stopSound() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Erro ao parar som: $e');
    }
  }

  /// Notificar nova mensagem recebida
  Future<void> notifyNewMessage({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    bool isPanic = false,
  }) async {
    // Se o chat estiver aberto, não mostrar notificação
    if (_isChatOpen) return;

    // Se for pânico, ativar modo pânico (som contínuo)

    // Mostrar notificação
    await _showNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: title,
          body: body,
        ),
        data: data ?? {'type': isPanic ? 'panic_action' : 'chat_message'},
      ),
      isPanic: isPanic,
    );

    // Tocar som (contínuo se for pânico)
    if (isPanic) {
      _playPanicSound();
    } else {
      _playSound();
    }
  }

  /// Marcar chat como aberto
  void markChatAsOpen() {
    _isChatOpen = true;
    _stopPanicSound(); // Parar som de pânico se estiver tocando
    _stopSound();
  }

  /// Marcar chat como fechado
  void markChatAsClosed() {
    _isChatOpen = false;
  }

  /// Limpar todas as notificações
  Future<void> clearAllNotifications() async {
    await _notifications.cancelAll();
  }
}
