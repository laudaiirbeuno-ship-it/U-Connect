import 'dart:async';
import 'package:uconnect/data/services/internal_chat_service.dart';
import 'package:uconnect/data/model/internal_chat_message.dart';
import 'package:uconnect/data/services/chat_notification_service.dart';

class ChatPollingService {
  final InternalChatService chatService;
  Timer? _pollTimer;
  int? _currentReceiverId;
  bool _isPolling = false;

  ChatPollingService(this.chatService);

  void startPolling({int? receiverId}) {
    _currentReceiverId = receiverId;
    _isPolling = true;

    // Poll rápido quando há conversa aberta (a cada 2 segundos)
    if (receiverId != null) {
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(Duration(seconds: 2), (_) {
        _checkNewMessages();
      });
    } else {
      // Poll lento quando não há conversa aberta (a cada 10 segundos)
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(Duration(seconds: 10), (_) {
        _checkNewMessages();
      });
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  Future<void> _checkNewMessages() async {
    if (!_isPolling) return;

    try {
      final response = await chatService.checkNewMessages();

      // Processar novas mensagens
      if (response.messages.isNotEmpty) {
        // Disparar notificações para novas mensagens
        for (var message in response.messages) {
          // Só notificar se não for a conversa atual aberta
          if (message.receiverId != _currentReceiverId) {
            // Verificar se é mensagem de pânico
            final isPanic = message.message.contains('🚨') || 
                           message.message.contains('PÂNICO') ||
                           message.message.contains('PANIC');
            
            await ChatNotificationService().notifyNewMessage(
              title: isPanic 
                  ? '🚨 AÇÃO DE PÂNICO 🚨'
                  : 'Nova mensagem',
              body: message.message.isNotEmpty 
                  ? message.message 
                  : 'Arquivo enviado',
              data: {
                'type': isPanic ? 'panic_action' : 'chat_message',
                'sender_id': message.senderId.toString(),
                'receiver_id': message.receiverId.toString(),
              },
              isPanic: isPanic,
            );
          }
        }
        
        _onNewMessages?.call(response.messages);
      }

      // Processar status de digitação
      if (response.typing.isNotEmpty) {
        _onTyping?.call(response.typing);
      }
    } catch (e) {
      print('Erro no polling: $e');
      // Não parar o polling em caso de erro, apenas logar
    }
  }

  Function(List<InternalChatMessage>)? _onNewMessages;
  Function(List<int>)? _onTyping;

  void onNewMessages(Function(List<InternalChatMessage>) callback) {
    _onNewMessages = callback;
  }

  void onTyping(Function(List<int>) callback) {
    _onTyping = callback;
  }

  void dispose() {
    stopPolling();
  }
}
