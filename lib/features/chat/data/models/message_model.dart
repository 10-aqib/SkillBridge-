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

  /// Storage paths of photos (chats/{chatId}/{senderId}/{messageId}/…).
  final List<String> attachments;

  /// Written on this device but not yet confirmed by the server.
  final bool isPending;

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
    this.attachments = const [],
    this.isPending = false,
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
    super.attachments,
    super.isPending,
  });

  factory MessageModel.fromSnapshot(DocumentSnapshot doc) => MessageModel.fromMap(
        doc.id,
        (doc.data() as Map<String, dynamic>?) ?? {},
        isPending: doc.metadata.hasPendingWrites,
      );

  factory MessageModel.fromMap(String id, Map<String, dynamic> data, {bool isPending = false}) {
    final raw = data['createdAt'];
    final createdAt = raw is Timestamp
        ? raw.toDate()
        : raw is int
            ? DateTime.fromMillisecondsSinceEpoch(raw)
            : raw is String
                ? DateTime.tryParse(raw) ?? DateTime.now()
                // Pending server time: shown as "now" until confirmed.
                : DateTime.now();
    final rawAttachments = data['attachments'];
    return MessageModel(
      id: id,
      chatId: (data['chatId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      senderName: (data['senderName'] ?? '').toString(),
      senderPhotoUrl: data['senderPhotoUrl']?.toString(),
      content: (data['content'] ?? '').toString(),
      type: MessageType.values.firstWhere((e) => e.name == (data['type'] ?? 'text'), orElse: () => MessageType.text),
      isRead: data['isRead'] == true,
      createdAt: createdAt,
      attachments: rawAttachments is Iterable ? rawAttachments.map((e) => e.toString()).toList() : const [],
      isPending: isPending,
    );
  }

  /// The document the security rules accept: own sender id, server time,
  /// unread, and photos only in the sender's folder for this message.
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (type == MessageType.image) 'attachments': attachments,
    };
  }
}
