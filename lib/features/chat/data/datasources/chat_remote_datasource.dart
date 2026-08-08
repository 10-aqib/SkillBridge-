import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/errors/app_exception.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/data/models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getUserChats(String userId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(MessageModel message);
  Future<void> markAsRead(String chatId, String userId);
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String currentUserName,
    String? currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    String? relatedJobId,
    String? relatedJobTitle,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;

  ChatRemoteDataSourceImpl(this._firestore);

  @override
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(FirestorePaths.chats)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => ChatModel.fromSnapshot(d)).toList();
      list.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return list;
    });
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(FirestorePaths.chats)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromSnapshot(d)).toList());
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    try {
      final batch = _firestore.batch();
      final msgRef = _firestore
          .collection(FirestorePaths.chats)
          .doc(message.chatId)
          .collection('messages')
          .doc();

      batch.set(msgRef, message.toMap());

      // Update chat thread's last message
      final chatRef = _firestore
          .collection(FirestorePaths.chats)
          .doc(message.chatId);
      batch.update(chatRef, {
        'lastMessage': message.content,
        'lastMessageSenderId': message.senderId,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection(FirestorePaths.chats).doc(chatId).update(
          {'unreadCount.$userId': 0});
    } catch (e) {
      throw ServerException('Failed to mark as read: $e');
    }
  }

  @override
  Future<String> createOrGetChatRoom({
    required String currentUserId,
    required String currentUserName,
    String? currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    String? relatedJobId,
    String? relatedJobTitle,
  }) async {
    try {
      final existing = await _firestore
          .collection(FirestorePaths.chats)
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (final doc in existing.docs) {
        final data = doc.data();
        final ids = List<String>.from(data['participantIds'] ?? []);
        if (ids.contains(otherUserId)) {
          return doc.id;
        }
      }

      final newDoc = _firestore.collection(FirestorePaths.chats).doc();
      await newDoc.set({
        'participantIds': [currentUserId, otherUserId],
        'participantNames': {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        'participantPhotos': {
          currentUserId: currentUserPhoto,
          otherUserId: otherUserPhoto,
        },
        'lastMessage': 'Chat started • بات چیت شروع ہوئی',
        'lastMessageSenderId': currentUserId,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUserId: 0,
          otherUserId: 1,
        },
        '?relatedJobId': relatedJobId,
        '?relatedJobTitle': relatedJobTitle,
      });

      return newDoc.id;
    } catch (e) {
      throw ServerException('Failed to create or get chat room: $e');
    }
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

/// Real-time list of chats for the current user
final userChatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(chatRemoteDataSourceProvider).getUserChats(user.uid);
});

/// Real-time messages for a given chat room
final chatMessagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  return ref.watch(chatRemoteDataSourceProvider).getMessages(chatId);
});
