import 'dart:convert';

class InternalChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final bool isReadByReceiver;
  final bool isRequest;
  final bool isDeleted;
  final bool isPinned;
  final String? filePath;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final int? replyToId;
  final InternalChatMessage? replyTo;
  final Map<String, dynamic>? reactions;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? senderName;
  final String? senderAvatar;

  InternalChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.isReadByReceiver,
    required this.isRequest,
    required this.isDeleted,
    required this.isPinned,
    this.filePath,
    this.fileUrl,
    this.fileType,
    this.fileName,
    this.replyToId,
    this.replyTo,
    this.reactions,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.senderAvatar,
  });

  factory InternalChatMessage.fromJson(Map<String, dynamic> json) {
    return InternalChatMessage(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      isReadByReceiver: json['is_read_by_receiver'] ?? false,
      isRequest: json['is_request'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      filePath: json['file_path'],
      fileUrl: json['file_url'],
      fileType: json['file_type'],
      fileName: json['file_name'],
      replyToId: json['reply_to_id'],
      replyTo: json['reply_to'] != null 
          ? InternalChatMessage.fromJson(json['reply_to']) 
          : null,
      reactions: json['reactions'] != null 
          ? (json['reactions'] is String 
              ? jsonDecode(json['reactions']) 
              : json['reactions']) 
          : null,
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at']) 
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      senderName: json['sender_name'] ?? json['sender']?['name'],
      senderAvatar: json['sender_avatar'] ?? json['sender']?['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_read': isRead,
      'is_read_by_receiver': isReadByReceiver,
      'is_request': isRequest,
      'is_deleted': isDeleted,
      'is_pinned': isPinned,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_name': fileName,
      'reply_to_id': replyToId,
      'reactions': reactions != null ? jsonEncode(reactions) : null,
      'edited_at': editedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get hasFile => fileUrl != null || filePath != null;
  bool get isImage => fileType != null && fileType!.startsWith('image/');
  bool get isAudio => fileType != null && fileType!.startsWith('audio/');
  bool get isDocument => fileType != null && !isImage && !isAudio;
}
