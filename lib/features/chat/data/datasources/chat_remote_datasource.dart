import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/media/private_media.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/data/models/message_model.dart';

/// Why a chat operation failed, for a clear message.
enum ChatFailure { notAllowed, unavailable, network, other }

ChatFailure chatFailureOf(Object e) {
  final code = e is FirebaseFunctionsException
      ? e.code
      : e is FirebaseException
          ? e.code
          : '';
  return switch (code) {
    'permission-denied' || 'unauthenticated' || 'unauthorized' => ChatFailure.notAllowed,
    'failed-precondition' || 'not-found' => ChatFailure.unavailable,
    'unavailable' || 'deadline-exceeded' || 'network-request-failed' || 'retry-limit-exceeded' => ChatFailure.network,
    _ => ChatFailure.other,
  };
}

/// Whether the other member's account can still receive messages, from
/// their public profile. A missing profile is not treated as gone (older
/// accounts may not have one yet); the server refuses messages to
/// suspended or deleted accounts either way.
enum ChatPeerStatus { active, suspended }

/// Messages shown per page; "Show earlier messages" adds another page.
const chatPageSize = 30;

/// Photos per message, and their size limit. Free plan (Phase S6): photos
/// are kept privately in Firestore (members only), so each is at most
/// [privateMediaMaxBytes]; they're shrunk when picked.
const chatMaxPhotos = 3;
const chatMaxPhotoBytes = privateMediaMaxBytes;

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getUserChats(String userId);
  Stream<ChatModel?> watchChat(String chatId);

  /// The newest [limit] messages, oldest first, including this device's
  /// unconfirmed ones ([MessageEntity.isPending]).
  Stream<List<MessageModel>> watchMessages(String chatId, {required int limit});

  /// A new message id. The same id is reused when sending is retried, so a
  /// retry can never create a second copy (the rules allow create only).
  String newMessageId(String chatId);
  Future<void> sendMessage(MessageModel message);

  /// Whether the server has the message (used after an uncertain failure).
  Future<bool> messageExists(String chatId, String messageId);

  /// Marks the conversation read for [userId] (server time).
  Future<void> markAsRead(String chatId, String userId);

  /// Opens or finds a conversation (free plan: written by this app, the
  /// rules check the relationship). With [jobId], a job conversation;
  /// without, a client's conversation with a worker.
  Future<String> openChat({required String otherUserId, String? jobId});

  /// Stores one photo privately for this message (members only) and returns
  /// its path, `chats/{chatId}/media/{messageId}_p{index}`.
  Future<String> uploadPhoto({
    required String chatId,
    required String senderId,
    required String messageId,
    required int index,
    required Uint8List bytes,
    required String contentType,
  });

  /// A photo's bytes for members (there is no shareable link).
  Future<Uint8List?> photoBytes(String path);

  Stream<ChatPeerStatus> watchPeer(String uid);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _chats => _firestore.collection(FirestorePaths.chats);
  CollectionReference<Map<String, dynamic>> _messages(String chatId) => _chats.doc(chatId).collection('messages');

  @override
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _chats.where('participantIds', arrayContains: userId).snapshots().map((snap) {
      final list = snap.docs.map(ChatModel.fromSnapshot).toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  @override
  Stream<ChatModel?> watchChat(String chatId) =>
      _chats.doc(chatId).snapshots().map((d) => d.exists ? ChatModel.fromSnapshot(d) : null);

  @override
  Stream<List<MessageModel>> watchMessages(String chatId, {required int limit}) {
    return _messages(chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map(MessageModel.fromSnapshot).toList().reversed.toList());
  }

  @override
  String newMessageId(String chatId) => _messages(chatId).doc().id;

  /// Free plan (Phase S5): the message, the chat's preview and the
  /// recipient's unread count (+1), and their in-app notification are one
  /// write; the rules accept the message only with its summary.
  @override
  Future<void> sendMessage(MessageModel message) async {
    final chatRef = _chats.doc(message.chatId);
    final chat = (await chatRef.get()).data() ?? const <String, dynamic>{};
    final ids = List<String>.from(chat['participantIds'] as List? ?? const []);
    final recipient = ids.firstWhere((id) => id != message.senderId, orElse: () => '');
    final preview = chatPreviewOf(message.content, isImage: message.type == MessageType.image);
    final batch = _firestore.batch()
      ..set(_messages(message.chatId).doc(message.id), message.toMap())
      ..update(chatRef, {
        'lastMessage': preview,
        'lastMessageSenderId': message.senderId,
        'lastMessageType': message.type == MessageType.image ? 'image' : 'text',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageId': message.id,
        if (recipient.isNotEmpty) 'unreadCount.$recipient': FieldValue.increment(1),
      });
    if (recipient.isNotEmpty) {
      final names = Map<String, dynamic>.from(chat['participantNames'] as Map? ?? const {});
      final from = (names[message.senderId] as String?)?.trim().isNotEmpty == true ? names[message.senderId] as String : 'Someone';
      batch.set(_firestore.collection(FirestorePaths.notifications).doc('msg_${message.id}'), {
        'userId': recipient,
        'title': 'New message from $from',
        'body': preview,
        'type': 'message',
        'payload': {'chatId': message.chatId, 'messageId': message.id},
        'referenceId': message.chatId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<bool> messageExists(String chatId, String messageId) async {
    final d = await _messages(chatId).doc(messageId).get(const GetOptions(source: Source.server));
    return d.exists;
  }

  @override
  Future<void> markAsRead(String chatId, String userId) => _chats.doc(chatId).update({
        'lastReadAt.$userId': FieldValue.serverTimestamp(),
        'unreadCount.$userId': 0,
      });

  /// Free plan (Phase S5; was openChatCall). Uses an existing conversation
  /// between the two (including an older one with a random id); otherwise
  /// creates `{jobId}_{workerId}` or `direct_{clientId}_{workerId}`, which
  /// the rules accept only for a real relationship.
  @override
  Future<String> openChat({required String otherUserId, String? jobId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw FirebaseException(plugin: 'chat', code: 'unauthenticated');
    if (otherUserId.isEmpty || otherUserId == uid) throw FirebaseException(plugin: 'chat', code: 'invalid-argument');
    final job = jobId != null && jobId.isNotEmpty ? jobId : null;

    // An existing conversation between the two, about the same job (or none).
    final mine = await _chats.where('participantIds', arrayContains: uid).get();
    for (final d in mine.docs) {
      final ids = List<String>.from(d.data()['participantIds'] as List? ?? const []);
      if (ids.length == 2 && ids.contains(otherUserId) && d.data()['relatedJobId'] == job) return d.id;
    }

    final me = (await _firestore.collection(FirestorePaths.users).doc(uid).get()).data() ?? const <String, dynamic>{};
    final other = (await _firestore.collection(FirestorePaths.publicProfiles).doc(otherUserId).get()).data();
    final iAmWorker = me['role'] == 'worker';
    String? title;
    String chatId;
    if (job != null) {
      final workerId = iAmWorker ? uid : otherUserId;
      chatId = '${job}_$workerId';
      // The job's title: from the job if readable, otherwise from my proposal.
      try {
        title = (await _firestore.collection(FirestorePaths.jobs).doc(job).get()).data()?['title'] as String?;
      } on FirebaseException catch (_) {
        title = null;
      }
      if (title == null && iAmWorker) {
        title = (await _firestore.collection(FirestorePaths.proposals).doc(chatId).get()).data()?['jobTitle'] as String?;
      }
    } else {
      chatId = 'direct_${uid}_$otherUserId';
    }
    String nameOf(Map<String, dynamic>? u) {
      final n = u?['displayName'] as String? ?? '';
      return n.trim().isEmpty ? 'SkillBridge user' : n;
    }

    final ref = _chats.doc(chatId);
    try {
      await ref.set({
        'participantIds': [uid, otherUserId],
        'participantNames': {uid: nameOf(me), otherUserId: nameOf(other)},
        'participantPhotos': {uid: me['photoUrl'], otherUserId: other?['photoUrl']},
        'lastMessage': '',
        'lastMessageSenderId': '',
        'lastMessageType': 'none',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {uid: 0, otherUserId: 0},
        'lastReadAt': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
        if (job != null) ...{'relatedJobId': job, 'relatedJobTitle': title ?? ''},
      });
      return chatId;
    } on FirebaseException catch (e) {
      // Created meanwhile (a second create is refused): use it if it's ours.
      if (e.code == 'permission-denied') {
        try {
          if ((await ref.get()).exists) return chatId;
        } on FirebaseException catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<String> uploadPhoto({
    required String chatId,
    required String senderId,
    required String messageId,
    required int index,
    required Uint8List bytes,
    required String contentType,
  }) {
    final type = privateImageTypes.contains(contentType) ? contentType : 'image/jpeg';
    return PrivateMedia.put(
      _chats.doc(chatId).collection('media').doc('${messageId}_p$index'),
      bytes,
      contentType: type,
      extra: {'senderId': senderId, 'messageId': messageId},
    );
  }

  @override
  Future<Uint8List?> photoBytes(String path) => PrivateMedia.read(_firestore, path);

  @override
  Stream<ChatPeerStatus> watchPeer(String uid) => _firestore
      .collection(FirestorePaths.publicProfiles)
      .doc(uid)
      .snapshots()
      .map((d) => d.data()?['isActive'] == false ? ChatPeerStatus.suspended : ChatPeerStatus.active);
}

/// The chat list preview for a message: its text, or "Photo" for a photo.
String chatPreviewOf(String content, {required bool isImage}) {
  final text = content.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (isImage) {
    final p = text.isNotEmpty ? 'Photo: $text' : 'Photo';
    return p.length > 120 ? p.substring(0, 120) : p;
  }
  return text.length > 120 ? text.substring(0, 120) : text;
}

/// Sends [message] once. If an earlier attempt reached the server but the
/// reply was lost, the retry is refused (create-only) and the message is
/// found on the server, so it counts as sent and no copy is created.
Future<void> deliverMessage(ChatRemoteDataSource ds, MessageModel message) async {
  try {
    await ds.sendMessage(message);
  } catch (e) {
    if (chatFailureOf(e) == ChatFailure.notAllowed) {
      bool landed = false;
      try {
        landed = await ds.messageExists(message.chatId, message.id);
      } catch (_) {}
      if (landed) return;
    }
    rethrow;
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

/// A refused read is final; other failures retry a few times.
Duration? _retry(int count, Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') return null;
  return count >= 3 ? null : Duration(milliseconds: 400 * (1 << count));
}

/// The signed-in user's conversations, most recent first.
final userChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(chatRemoteDataSourceProvider).getUserChats(uid);
}, retry: _retry);

/// Conversations with unread messages for the signed-in user.
final unreadChatsCountProvider = Provider<int>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
  final chats = ref.watch(userChatsStreamProvider).value ?? const [];
  return uid == null ? 0 : chats.where((c) => c.unreadFor(uid) > 0).length;
});

/// One conversation, live (null when it doesn't exist or isn't yours).
final chatByIdProvider = StreamProvider.family<ChatModel?, String>((ref, chatId) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref.watch(chatRemoteDataSourceProvider).watchChat(chatId);
}, retry: _retry);

/// The newest messages of a conversation; a larger [limit] shows older ones.
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, ({String chatId, int limit})>((ref, key) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref.watch(chatRemoteDataSourceProvider).watchMessages(key.chatId, limit: key.limit);
}, retry: _retry);

/// A chat photo's bytes (members only), kept while it is on screen.
final chatPhotoProvider = FutureProvider.autoDispose.family<Uint8List?, String>((ref, path) {
  return ref.watch(chatRemoteDataSourceProvider).photoBytes(path);
});

final chatPeerStatusProvider = StreamProvider.family<ChatPeerStatus, String>((ref, uid) {
  return ref.watch(chatRemoteDataSourceProvider).watchPeer(uid);
}, retry: _retry);
