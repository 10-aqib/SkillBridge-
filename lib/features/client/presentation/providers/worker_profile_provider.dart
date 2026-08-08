import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

/// Provider to fetch a specific worker's profile by their UID.
final workerProfileProvider =
    FutureProvider.family<UserEntity?, String>((ref, workerId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('users').doc(workerId).get();

  if (doc.exists && doc.data() != null) {
    return UserModel.fromFirestore(doc);
  }
  return null;
});
