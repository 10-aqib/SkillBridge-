import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/data/models/message_model.dart';

/// In-memory conversations for widget tests. Not Firebase: the matching
/// rules are tested in rules-tests/ and the functions in functions/test/.
class FakeChatStore implements ChatRemoteDataSource {
  FakeChatStore({Map<String, Map<String, dynamic>> chats = const {}, Map<String, List<MessageModel>> messages = const {}}) {
    for (final e in chats.entries) {
      this.chats[e.key] = Map<String, dynamic>.from(e.value);
    }
    for (final e in messages.entries) {
      this.messages[e.key] = [...e.value];
    }
  }

  final Map<String, Map<String, dynamic>> chats = {};
  final Map<String, List<MessageModel>> messages = {};
  final Map<String, ChatPeerStatus> peers = {};
  final _changes = StreamController<void>.broadcast();

  /// Calls, in order, for assertions.
  final List<String> calls = [];
  final List<int> limits = [];
  final List<String> uploads = [];

  /// Fail the next sends with this error (null: succeed).
  Object? sendError;

  /// The first send reaches the server but its reply is lost (the app sees
  /// an error); a retry is then refused as a duplicate.
  bool loseFirstReply = false;
  Object? listError;
  Object? chatError;
  int _ids = 0;

  void changed() => _changes.add(null);

  Stream<T> _live<T>(T Function() read, [Object? Function()? error]) async* {
    final e = error?.call();
    if (e != null) throw e;
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  Stream<List<ChatModel>> getUserChats(String userId) => _live(() {
        final list = [
          for (final e in chats.entries)
            if ((e.value['participantIds'] as List).contains(userId)) ChatModel.fromMap(e.key, e.value),
        ];
        return list..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }, () => listError);

  @override
  Stream<ChatModel?> watchChat(String chatId) =>
      _live(() => chats.containsKey(chatId) ? ChatModel.fromMap(chatId, chats[chatId]!) : null, () => chatError);

  @override
  Stream<List<MessageModel>> watchMessages(String chatId, {required int limit}) {
    limits.add(limit);
    return _live(() {
      final all = [...?messages[chatId]]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return all.length > limit ? all.sublist(all.length - limit) : all;
    });
  }

  @override
  String newMessageId(String chatId) => 'msg_test_${++_ids}';

  @override
  Future<void> sendMessage(MessageModel message) async {
    calls.add('send:${message.id}:${message.type.name}:${message.content}:${message.attachments.join(',')}');
    final list = messages.putIfAbsent(message.chatId, () => []);
    if (loseFirstReply) {
      loseFirstReply = false;
      list.add(message);
      changed();
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    if (list.any((m) => m.id == message.id)) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'); // create-only
    }
    if (sendError != null) throw sendError!;
    list.add(message);
    changed();
  }

  @override
  Future<bool> messageExists(String chatId, String messageId) async {
    calls.add('exists:$messageId');
    return messages[chatId]?.any((m) => m.id == messageId) ?? false;
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    calls.add('read:$chatId:$userId');
    final c = chats[chatId]!;
    c['unreadCount'] = {...(c['unreadCount'] as Map? ?? {}), userId: 0};
    c['lastReadAt'] = {...(c['lastReadAt'] as Map? ?? {}), userId: Timestamp.now()};
    changed();
  }

  @override
  Future<String> openChat({required String otherUserId, String? jobId}) async {
    calls.add('open:$otherUserId:${jobId ?? '-'}');
    return jobId == null ? 'direct_me_$otherUserId' : '${jobId}_$otherUserId';
  }

  @override
  Future<String> uploadPhoto({
    required String chatId,
    required String senderId,
    required String messageId,
    required int index,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = 'chats/$chatId/$senderId/$messageId/p$index.jpg';
    uploads.add(path);
    return path;
  }

  Uint8List? photo;

  @override
  Future<Uint8List?> photoBytes(String path) async => photo ?? (throw Exception('no network in tests'));

  @override
  Stream<ChatPeerStatus> watchPeer(String uid) => _live(() => peers[uid] ?? ChatPeerStatus.active);
}

/// A conversation document as openChatCall and the message trigger keep it.
Map<String, dynamic> chatDoc({
  String a = 'client_1',
  String b = 'w1',
  String aName = 'Ayesha Khan',
  String bName = 'Bilal Ahmed',
  String last = 'See you at 10',
  String lastSender = 'w1',
  String lastType = 'text',
  DateTime? lastAt,
  Map<String, int>? unread,
  Map<String, DateTime>? readAt,
  String? jobId = 'j1',
  String jobTitle = 'Fix two kitchen sockets',
}) =>
    {
      'participantIds': [a, b],
      'participantNames': {a: aName, b: bName},
      'participantPhotos': {a: null, b: null},
      'lastMessage': last,
      'lastMessageSenderId': lastSender,
      'lastMessageType': lastType,
      'lastMessageAt': Timestamp.fromDate(lastAt ?? DateTime(2026, 11, 10, 9)),
      'unreadCount': unread ?? {a: 0, b: 0},
      'lastReadAt': {for (final e in (readAt ?? {}).entries) e.key: Timestamp.fromDate(e.value)},
      'relatedJobId': ?jobId,
      if (jobId != null) 'relatedJobTitle': jobTitle,
    };

MessageModel msg(String id, String sender, String text, DateTime at, {String chatId = 'k', List<String> photos = const []}) => MessageModel(
      id: id,
      chatId: chatId,
      senderId: sender,
      senderName: sender,
      content: text,
      type: photos.isEmpty ? MessageType.text : MessageType.image,
      isRead: false,
      createdAt: at,
      attachments: photos,
    );
