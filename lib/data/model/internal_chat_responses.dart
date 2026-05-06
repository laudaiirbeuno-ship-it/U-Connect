import 'package:uconnect/data/model/internal_chat_message.dart';

class MessagesResponse {
  final List<InternalChatMessage> messages;
  final Map<String, dynamic> user;

  MessagesResponse({
    required this.messages,
    required this.user,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) {
    return MessagesResponse(
      messages: (json['messages'] as List? ?? [])
          .map((m) => InternalChatMessage.fromJson(m))
          .toList(),
      user: json['user'] ?? {},
    );
  }
}

class CheckMessagesResponse {
  final List<InternalChatMessage> messages;
  final List<int> typing;
  final Map<String, dynamic> user;

  CheckMessagesResponse({
    required this.messages,
    required this.typing,
    required this.user,
  });

  factory CheckMessagesResponse.fromJson(Map<String, dynamic> json) {
    return CheckMessagesResponse(
      messages: (json['messages'] as List? ?? [])
          .map((m) => InternalChatMessage.fromJson(m))
          .toList(),
      typing: (json['typing'] as List? ?? []).map((t) => t as int).toList(),
      user: json['user'] ?? {},
    );
  }
}
