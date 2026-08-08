import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system }

class MessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });
}

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.senderName,
    super.senderPhotoUrl,
    required super.content,
    required super.type,
    required super.isRead,
    required super.createdAt,
  });

  factory MessageModel.fromSnapshot(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    DateTime createdAt = DateTime.now();
    final rawTimestamp = data['createdAt'];
    if (rawTimestamp is Timestamp) {
      createdAt = rawTimestamp.toDate();
    } else if (rawTimestamp is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      createdAt = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    return MessageModel(
      id: doc.id,
      chatId: (data['chatId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      senderPhotoUrl: data['senderPhotoUrl']?.toString(),
      content: (data['content'] ?? '').toString(),
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      isRead: data['isRead'] ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
