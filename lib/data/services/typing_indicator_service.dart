import 'dart:async';
import 'package:uconnect/data/services/internal_chat_service.dart';

class TypingIndicator {
  Timer? _typingTimer;
  final InternalChatService chatService;
  final int receiverId;

  TypingIndicator(this.chatService, this.receiverId);

  void onTextChanged() {
    // Cancelar timer anterior
    _typingTimer?.cancel();

    // Enviar status de digitação
    chatService.setTyping(receiverId).catchError((e) {
      print('Erro ao enviar status de digitação: $e');
    });

    // Parar de digitar após 3 segundos de inatividade
    _typingTimer = Timer(Duration(seconds: 3), () {
      // O servidor remove automaticamente após 5 segundos
    });
  }

  void dispose() {
    _typingTimer?.cancel();
  }
}
