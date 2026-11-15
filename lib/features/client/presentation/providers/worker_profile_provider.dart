import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/constants/firestore_paths.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

/// Another person's public profile (worker or client) by UID.
///
/// Reads publicProfiles/{uid}, the allowlisted public view (written by the
/// owner's app, checked by the rules; see PublicProfileSync). The full users/{uid} document (phone, email, addresses) is
/// readable only by its owner, so private fields here are always empty.
final workerProfileProvider =
    FutureProvider.family<UserEntity?, String>((ref, workerId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection(FirestorePaths.publicProfiles).doc(workerId).get();

  if (doc.exists && doc.data() != null) {
    return UserModel.fromFirestore(doc);
  }
  return null;
});
