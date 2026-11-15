import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/contracts/data/models/contract_activity.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';

final contractRemoteDataSourceProvider = Provider<ContractRemoteDataSource>((ref) {
  return ContractRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

/// Hiring and lifecycle steps (transactions checked by the rules).
final contractActionsProvider = Provider<ContractActions>((ref) {
  return ContractActionsImpl(
      ref.watch(firestoreProvider), ref.watch(firebaseAuthProvider), ref.watch(firebaseStorageProvider));
});

/// A refused read is final; other failures retry a few times.
Duration? _retry(int count, Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') return null;
  return count >= 3 ? null : Duration(milliseconds: 400 * (1 << count));
}

/// The signed-in user's contracts (as client or as worker), newest first.
final userContractsStreamProvider = StreamProvider<List<ContractEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final ds = ref.watch(contractRemoteDataSourceProvider);
  return user.isClient ? ds.getContractsByClient(user.uid) : ds.getContractsByWorker(user.uid);
}, retry: _retry);

/// One contract, live. Restarts when the signed-in account changes.
final contractByIdProvider = StreamProvider.family<ContractEntity?, String>((ref, id) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref.watch(contractRemoteDataSourceProvider).watchContract(id);
}, retry: _retry);

/// The signed-in party's contract for a job (null when there is none).
final contractForJobProvider = StreamProvider.family<ContractEntity?, String>((ref, jobId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(contractRemoteDataSourceProvider).watchContractForJob(jobId, uid: user.uid, asClient: user.isClient);
}, retry: _retry);

/// The worker's progress updates on a contract, newest first.
final contractUpdatesProvider = StreamProvider.family<List<ContractUpdate>, String>((ref, id) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref.watch(contractRemoteDataSourceProvider).watchUpdates(id);
}, retry: _retry);

/// Every submission of the work on a contract, oldest first.
final contractSubmissionsProvider = StreamProvider.family<List<ContractSubmission>, String>((ref, id) {
  ref.watch(currentUserProvider.select((u) => u?.uid));
  return ref.watch(contractRemoteDataSourceProvider).watchSubmissions(id);
}, retry: _retry);

/// An evidence photo's bytes (parties only), kept while on screen.
final contractEvidenceProvider = FutureProvider.autoDispose.family<Uint8List?, String>((ref, path) {
  return ref.watch(contractActionsProvider).evidenceBytes(path);
});
