import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';

/// Opens (or starts) the chat between a client and a worker about one job.
/// The trusted function (openChatCall) allows it only when the worker is
/// linked to the job: a public open job, a proposal, or being the selected
/// or hired worker. Returns false when it could not be opened.
///
/// The names and photo are no longer sent: the function reads them from
/// the two accounts. They stay in the signature for existing callers.
Future<bool> openJobChat(
  BuildContext context,
  WidgetRef ref, {
  required UserEntity me,
  required String otherUserId,
  required String otherUserName,
  String? otherUserPhoto,
  required String jobId,
  required String jobTitle,
  required String workerId,
}) =>
    _open(context, ref, otherUserId: otherUserId, jobId: jobId);

/// A client's conversation with a worker outside a job (the server refuses
/// it for anyone else). Returns false when it could not be opened.
Future<bool> openDirectChat(BuildContext context, WidgetRef ref, {required String workerId}) =>
    _open(context, ref, otherUserId: workerId);

Future<bool> _open(BuildContext context, WidgetRef ref, {required String otherUserId, String? jobId}) async {
  try {
    final chatId = await ref.read(chatRemoteDataSourceProvider).openChat(otherUserId: otherUserId, jobId: jobId);
    if (!context.mounted) return false;
    context.push(RouteNames.chatRoomLocation(chatId));
    return true;
  } catch (_) {
    return false;
  }
}
