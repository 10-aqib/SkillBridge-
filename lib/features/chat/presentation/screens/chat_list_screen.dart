import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/presentation/widgets/chat_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The signed-in user's conversations, most recent first, from Firestore.
/// Previews, times and unread counts are kept by the server.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final chats = ref.watch(userChatsStreamProvider);
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final edge = SbLayout.edge(context);
    final list = chats.value;

    Widget body;
    if (list == null && chats.hasError) {
      body = SbStateView(
        kind: online ? SbStateKind.error : SbStateKind.offline,
        title: l.chatsLoadError,
        message: online ? l.errNetwork : l.chatsOffline,
        actionLabel: l.tryAgain,
        onAction: () => ref.invalidate(userChatsStreamProvider),
      );
    } else if (list == null) {
      body = SbSkeletonList(
        item: const SbListRowSkeleton(),
        count: 6,
        padding: EdgeInsets.symmetric(vertical: SbSpace.s3, horizontal: edge),
        label: l.loading,
      );
    } else if (list.isEmpty) {
      body = RefreshIndicator(
        onRefresh: () async => ref.invalidate(userChatsStreamProvider),
        child: ListView(children: [
          if (!online) Padding(padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, 0), child: SbOfflineNote(message: l.chatsOffline)),
          SizedBox(
            height: 420,
            child: SbStateView(
              kind: SbStateKind.empty,
              icon: Icons.chat_bubble_outline_rounded,
              title: l.chatsEmptyTitle,
              message: (me?.isClient ?? false) ? l.chatsEmptyClient : l.chatsEmptyWorker,
            ),
          ),
        ]),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => ref.invalidate(userChatsStreamProvider),
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: SbSpace.s8),
          itemCount: list.length + 1,
          separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : Divider(height: 1, indent: edge + 48 + SbSpace.s3, color: context.sb.border),
          itemBuilder: (context, i) {
            if (i == 0) {
              return online
                  ? const SizedBox.shrink()
                  : Padding(padding: EdgeInsets.fromLTRB(edge, SbSpace.s3, edge, SbSpace.s2), child: SbOfflineNote(message: l.chatsOffline));
            }
            return ChatListTile(chat: list[i - 1], me: me?.uid ?? '');
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.chatsTitle)),
      body: SbReadableWidth(maxWidth: 840, child: SbLoadSwitcher(loading: list == null && !chats.hasError, child: body)),
    );
  }
}

/// One conversation: the other person, the job it is about, the last
/// message (yours prefixed with "You:"), when, and how many are unread.
class ChatListTile extends StatelessWidget {
  const ChatListTile({super.key, required this.chat, required this.me});
  final ChatEntity chat;
  final String me;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final unread = chat.unreadFor(me);
    final name = chat.otherName(me);
    final raw = chat.lastMessageType == ChatLastMessageType.image && chat.lastMessage.isEmpty ? l.chatPhoto : chat.lastMessage;
    final preview = chat.isEmpty
        ? l.chatNoMessagesYet
        : chat.lastMessageSenderId == me
            ? l.chatYouPrefix(raw)
            : raw;
    final time = chatListTime(context, chat.lastMessageAt);
    final strong = unread > 0;

    return Semantics(
      button: true,
      label: [name, if (chat.relatedJobTitle?.isNotEmpty ?? false) chat.relatedJobTitle!, preview, time, if (strong) l.chatUnreadCount(unread)].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(RouteNames.chatRoomLocation(chat.id)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SbLayout.edge(context), vertical: SbSpace.s3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SbAvatar(name: name, imageUrl: chat.otherPhoto(me), size: 48),
            const SizedBox(width: SbSpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(name, style: t.titleSmall!.copyWith(fontWeight: strong ? FontWeight.w700 : FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: SbSpace.s2),
                  Text(time, style: t.bodySmall!.copyWith(color: strong ? sb.primary : sb.textSecondary, fontWeight: strong ? FontWeight.w600 : null)),
                ]),
                if (chat.relatedJobTitle?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      Icon(Icons.work_outline_rounded, size: 14, color: sb.textSecondary),
                      const SizedBox(width: SbSpace.s1),
                      Expanded(child: Text(chat.relatedJobTitle!, style: t.labelSmall!.copyWith(color: sb.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                const SizedBox(height: SbSpace.s1),
                Row(children: [
                  if (chat.lastMessageType == ChatLastMessageType.image) ...[
                    Icon(Icons.photo_outlined, size: 16, color: sb.textSecondary),
                    const SizedBox(width: SbSpace.s1),
                  ],
                  Expanded(
                    child: Text(
                      preview,
                      style: t.bodyMedium!.copyWith(
                        color: strong ? sb.text : sb.textSecondary,
                        fontWeight: strong ? FontWeight.w600 : null,
                        fontStyle: chat.isEmpty ? FontStyle.italic : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (strong) ...[
                    const SizedBox(width: SbSpace.s2),
                    Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: sb.primary, borderRadius: BorderRadius.circular(SbRadius.full)),
                      child: Text(unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center, style: t.labelSmall!.copyWith(color: sb.onPrimary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
