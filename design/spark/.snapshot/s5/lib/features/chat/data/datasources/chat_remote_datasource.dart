import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Photos per message, and their size limit (matches storage.rules).
const chatMaxPhotos = 3;
const chatMaxPhotoBytes = 5 * 1024 * 1024;

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

  /// Opens or finds a conversation through the trusted function, which
  /// checks the relationship. With [jobId], a job conversation; without, a
  /// client's conversation with a worker.
  Future<String> openChat({required String otherUserId, String? jobId});

  /// Uploads one photo into the sender's folder for this message and
  /// returns its storage path.
  Future<String> uploadPhoto({
    required String chatId,
    required String senderId,
    required String messageId,
    required int index,
    required Uint8List bytes,
    required String contentType,
  });

  /// A photo's bytes for members (no shareable download link is created).
  Future<Uint8List?> photoBytes(String path);

  Stream<ChatPeerStatus> watchPeer(String uid);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._firestore, this._functions, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

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

  @override
  Future<void> sendMessage(MessageModel message) => _messages(message.chatId).doc(message.id).set(message.toMap());

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

  @override
  Future<String> openChat({required String otherUserId, String? jobId}) async {
    final res = await _functions.httpsCallable('openChatCall').call<Map<String, dynamic>>({
      'otherUserId': otherUserId,
      'jobId': ?jobId,
    });
    return res.data['chatId'] as String;
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
    final ext = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final path = 'chats/$chatId/$senderId/$messageId/p$index.$ext';
    await _storage.ref(path).putData(bytes, SettableMetadata(contentType: ext == 'jpg' ? 'image/jpeg' : contentType));
    return path;
  }

  @override
  Future<Uint8List?> photoBytes(String path) => _storage.ref(path).getData(chatMaxPhotoBytes);

  @override
  Stream<ChatPeerStatus> watchPeer(String uid) => _firestore
      .collection(FirestorePaths.publicProfiles)
      .doc(uid)
      .snapshots()
      .map((d) => d.data()?['isActive'] == false ? ChatPeerStatus.suspended : ChatPeerStatus.active);
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
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseStorageProvider),
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
