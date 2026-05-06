class InternalChatContact {
  final int id;
  final String name;
  final String email;
  final bool online;
  final int unread;
  final String? avatar;
  final String? lastActivity;
  final String? lastMessage;
  final String? lastMessageTime;

  InternalChatContact({
    required this.id,
    required this.name,
    required this.email,
    required this.online,
    required this.unread,
    this.avatar,
    this.lastActivity,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory InternalChatContact.fromJson(Map<String, dynamic> json) {
    return InternalChatContact(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      online: json['online'] ?? false,
      unread: json['unread'] ?? 0,
      avatar: json['avatar'],
      lastActivity: json['last_activity'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'online': online,
      'unread': unread,
      'avatar': avatar,
      'last_activity': lastActivity,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
    };
  }
}
