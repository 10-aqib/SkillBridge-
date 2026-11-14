import 'package:cloud_firestore/cloud_firestore.dart';

/// What the last message in a conversation was (kept by the server).
enum ChatLastMessageType { none, text, image }

class ChatEntity {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final String lastMessageSenderId;
  final ChatLastMessageType lastMessageType;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;

  /// When each member last opened the conversation (server time).
  final Map<String, DateTime> lastReadAt;
  final String? relatedJobId;
  final String? relatedJobTitle;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageSenderId,
    this.lastMessageType = ChatLastMessageType.text,
    required this.lastMessageAt,
    required this.unreadCount,
    this.lastReadAt = const {},
    this.relatedJobId,
    this.relatedJobTitle,
  });

  /// The other member (empty when the conversation is malformed).
  String otherId(String me) => participantIds.firstWhere((id) => id != me, orElse: () => '');

  String otherName(String me) {
    final n = participantNames[otherId(me)]?.trim() ?? '';
    return n.isEmpty ? 'SkillBridge user' : n;
  }

  String? otherPhoto(String me) => participantPhotos[otherId(me)];

  int unreadFor(String me) => unreadCount[me] ?? 0;

  /// No message has been sent yet.
  bool get isEmpty => lastMessageType == ChatLastMessageType.none || (lastMessage.isEmpty && lastMessageSenderId.isEmpty);
}

DateTime? _date(Object? raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.participantIds,
    required super.participantNames,
    required super.participantPhotos,
    required super.lastMessage,
    required super.lastMessageSenderId,
    super.lastMessageType,
    required super.lastMessageAt,
    required super.unreadCount,
    super.lastReadAt,
    super.relatedJobId,
    super.relatedJobTitle,
  });

  factory ChatModel.fromSnapshot(DocumentSnapshot doc) =>
      ChatModel.fromMap(doc.id, (doc.data() as Map<String, dynamic>?) ?? {});

  factory ChatModel.fromMap(String id, Map<String, dynamic> data) {
    final rawIds = data['participantIds'];
    final participantIds = rawIds is Iterable ? rawIds.map((e) => e.toString()).toList() : <String>[];

    final participantNames = <String, String>{};
    final rawNames = data['participantNames'];
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        if (k != null) participantNames[k.toString()] = v?.toString() ?? '';
      });
    }

    final participantPhotos = <String, String?>{};
    final rawPhotos = data['participantPhotos'];
    if (rawPhotos is Map) {
      rawPhotos.forEach((k, v) {
        if (k != null) participantPhotos[k.toString()] = v?.toString();
      });
    }

    final unreadCount = <String, int>{};
    final rawUnread = data['unreadCount'];
    if (rawUnread is Map) {
      rawUnread.forEach((k, v) {
        if (k != null) unreadCount[k.toString()] = v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
      });
    }

    final lastReadAt = <String, DateTime>{};
    final rawRead = data['lastReadAt'];
    if (rawRead is Map) {
      rawRead.forEach((k, v) {
        final d = _date(v);
        if (k != null && d != null) lastReadAt[k.toString()] = d;
      });
    }

    final type = switch (data['lastMessageType']) {
      'none' => ChatLastMessageType.none,
      'image' => ChatLastMessageType.image,
      _ => ChatLastMessageType.text,
    };

    return ChatModel(
      id: id,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageSenderId: (data['lastMessageSenderId'] ?? '').toString(),
      lastMessageType: type,
      // A pending server time is "now" until the server confirms it.
      lastMessageAt: _date(data['lastMessageAt']) ?? _date(data['createdAt']) ?? DateTime.now(),
      unreadCount: unreadCount,
      lastReadAt: lastReadAt,
      relatedJobId: data['relatedJobId']?.toString(),
      relatedJobTitle: data['relatedJobTitle']?.toString(),
    );
  }
}
