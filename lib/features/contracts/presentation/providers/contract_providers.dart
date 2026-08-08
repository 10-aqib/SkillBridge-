import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/providers/firebase_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/datasources/contract_remote_datasource.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';

final contractRemoteDataSourceProvider =
    Provider<ContractRemoteDataSource>((ref) {
  return ContractRemoteDataSourceImpl(ref.watch(firestoreProvider));
});

/// Real-time stream of contracts for current user (Worker or Client)
final userContractsStreamProvider =
    StreamProvider<List<ContractEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  if (user.isClient) {
    return ref
        .watch(contractRemoteDataSourceProvider)
        .getContractsByClient(user.uid);
  } else {
    return ref
        .watch(contractRemoteDataSourceProvider)
        .getContractsByWorker(user.uid);
  }
});
