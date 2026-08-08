import 'package:cloud_firestore/cloud_firestore.dart';

class ChatEntity {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;
  final String? relatedJobId;
  final String? relatedJobTitle;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageAt,
    required this.unreadCount,
    this.relatedJobId,
    this.relatedJobTitle,
  });
}

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.participantIds,
    required super.participantNames,
    required super.participantPhotos,
    required super.lastMessage,
    required super.lastMessageSenderId,
    required super.lastMessageAt,
    required super.unreadCount,
    super.relatedJobId,
    super.relatedJobTitle,
  });

  factory ChatModel.fromSnapshot(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    final rawIds = data['participantIds'];
    final participantIds = rawIds is Iterable
        ? rawIds.map((e) => e.toString()).toList()
        : <String>[];

    final rawNames = data['participantNames'];
    final participantNames = <String, String>{};
    if (rawNames is Map) {
      rawNames.forEach((k, v) {
        if (k != null) participantNames[k.toString()] = v?.toString() ?? 'User';
      });
    }

    final rawPhotos = data['participantPhotos'];
    final participantPhotos = <String, String?>{};
    if (rawPhotos is Map) {
      rawPhotos.forEach((k, v) {
        if (k != null) participantPhotos[k.toString()] = v?.toString();
      });
    }

    final rawUnread = data['unreadCount'];
    final unreadCount = <String, int>{};
    if (rawUnread is Map) {
      rawUnread.forEach((k, v) {
        if (k != null) {
          final val = v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;
          unreadCount[k.toString()] = val;
        }
      });
    }

    DateTime lastMessageAt = DateTime.now();
    final rawTimestamp = data['lastMessageAt'];
    if (rawTimestamp is Timestamp) {
      lastMessageAt = rawTimestamp.toDate();
    } else if (rawTimestamp is int) {
      lastMessageAt = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      lastMessageAt = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }

    return ChatModel(
      id: doc.id,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastMessageSenderId: (data['lastMessageSenderId'] ?? '').toString(),
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      relatedJobId: data['relatedJobId']?.toString(),
      relatedJobTitle: data['relatedJobTitle']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
      'relatedJobId': relatedJobId,
      'relatedJobTitle': relatedJobTitle,
    };
  }
}
