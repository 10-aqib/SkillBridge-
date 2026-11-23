import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/data/models/message_model.dart';
import 'package:skill_bridge/features/chat/presentation/widgets/chat_ui.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

typedef ChatPhoto = ({Uint8List bytes, String contentType});
typedef ChatPhotoPicker = Future<ChatPhoto?> Function();

Future<ChatPhoto?> _pickWithImagePicker() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 70);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.name.toLowerCase();
  final type = file.mimeType ?? (name.endsWith('.png') ? 'image/png' : name.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
  return (bytes: bytes, contentType: type);
}

/// Longest message the composer accepts (the rules allow up to 5000).
const chatMaxLength = 2000;

/// A message this device is sending: kept until the server has it, so a
/// failed one can be retried with the same id (never a second copy).
class _Outgoing {
  _Outgoing({required this.id, required this.text, required this.photos, required this.at})
      : uploaded = List<String?>.filled(photos.length, null);
  final String id;
  final String text;
  final List<ChatPhoto> photos;
  final DateTime at;
  final List<String?> uploaded;
  bool failed = false;
  ChatFailure? reason;
}

/// One conversation, opened by id. Only its two members can read it (the
/// rules refuse anyone else); the server keeps previews and unread counts.
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.chatId, this.photoPicker});
  final String chatId;
  final ChatPhotoPicker? photoPicker;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _input = TextEditingController();
  final List<ChatPhoto> _draftPhotos = [];
  final Map<String, _Outgoing> _outbox = {};
  int _limit = chatPageSize;
  List<MessageModel>? _shown;
  String? _readKey;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  ChatRemoteDataSource get _ds => ref.read(chatRemoteDataSourceProvider);

  /// Marks the conversation read when something new from the other person
  /// arrives while it is open (once per change).
  void _markReadIfNeeded(ChatEntity chat, String me) {
    final lastRead = chat.lastReadAt[me];
    final fromOther = chat.lastMessageSenderId.isNotEmpty && chat.lastMessageSenderId != me;
    final needs = chat.unreadFor(me) > 0 || (fromOther && (lastRead == null || lastRead.isBefore(chat.lastMessageAt)));
    final key = '${chat.lastMessageAt.millisecondsSinceEpoch}:${chat.unreadFor(me)}';
    if (!needs || key == _readKey) return;
    _readKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ds.markAsRead(widget.chatId, me).catchError((_) {});
    });
  }

  Future<void> _addPhoto() async {
    final l = context.l10n;
    if (_draftPhotos.length >= chatMaxPhotos) {
      context.showSnackBar(l.chatPhotoLimit, isError: true);
      return;
    }
    final picked = await (widget.photoPicker ?? _pickWithImagePicker)();
    if (picked == null || !mounted) return;
    if (picked.bytes.length > chatMaxPhotoBytes) {
      context.showSnackBar(l.chatPhotoTooLarge, isError: true);
      return;
    }
    if (!const ['image/jpeg', 'image/png', 'image/webp'].contains(picked.contentType)) {
      context.showSnackBar(l.chatPhotoType, isError: true);
      return;
    }
    setState(() => _draftPhotos.add(picked));
  }

  void _send(UserEntity me) {
    final text = _input.text.trim();
    if (text.isEmpty && _draftPhotos.isEmpty) return;
    if (text.length > chatMaxLength) {
      context.showSnackBar(context.l10n.chatTooLong, isError: true);
      return;
    }
    final o = _Outgoing(id: _ds.newMessageId(widget.chatId), text: text, photos: List.of(_draftPhotos), at: DateTime.now());
    setState(() {
      _outbox[o.id] = o;
      _input.clear();
      _draftPhotos.clear();
    });
    _deliver(o, me);
  }

  Future<void> _deliver(_Outgoing o, UserEntity me) async {
    setState(() {
      o.failed = false;
      o.reason = null;
    });
    try {
      for (var i = 0; i < o.photos.length; i++) {
        // Photos already uploaded on an earlier try are kept (never re-sent).
        o.uploaded[i] ??= await _ds.uploadPhoto(
          chatId: widget.chatId,
          senderId: me.uid,
          messageId: o.id,
          index: i + 1,
          bytes: o.photos[i].bytes,
          contentType: o.photos[i].contentType,
        );
      }
      await deliverMessage(
        _ds,
        MessageModel(
          id: o.id,
          chatId: widget.chatId,
          senderId: me.uid,
          senderName: me.formattedDisplayName,
          senderPhotoUrl: me.photoUrl,
          content: o.text,
          type: o.photos.isEmpty ? MessageType.text : MessageType.image,
          isRead: false,
          createdAt: o.at,
          attachments: o.uploaded.whereType<String>().toList(),
        ),
      );
      if (mounted) setState(() => _outbox.remove(o.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        o.failed = true;
        o.reason = chatFailureOf(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final me = ref.watch(currentUserProvider);
    final chatAsync = ref.watch(chatByIdProvider(widget.chatId));
    final chat = chatAsync.value;

    if (me == null) return const Scaffold(body: SizedBox.shrink());

    // Not loaded yet, refused, missing, or not a member.
    if (chat == null || !chat.participantIds.contains(me.uid)) {
      final refused = chatAsync.error is FirebaseException && (chatAsync.error as FirebaseException).code == 'permission-denied';
      final Widget body;
      if (chatAsync.isLoading && chat == null) {
        body = const Center(child: CircularProgressIndicator());
      } else if (chatAsync.hasError && !refused) {
        body = SbStateView(
          kind: SbStateKind.error,
          title: l.chatRoomLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(chatByIdProvider(widget.chatId)),
        );
      } else {
        body = SbStateView(
          kind: SbStateKind.permission,
          icon: Icons.forum_outlined,
          title: l.chatRoomUnavailableTitle,
          message: l.chatRoomUnavailableBody,
          actionLabel: l.chatsTitle,
          onAction: () => context.canPop() ? context.pop() : context.go(me.isClient ? RouteNames.clientChatsPath : RouteNames.workerChatsPath),
        );
      }
      return Scaffold(appBar: AppBar(), body: body);
    }

    _markReadIfNeeded(chat, me.uid);
    final otherId = chat.otherId(me.uid);
    final otherName = chat.otherName(me.uid);
    final peer = ref.watch(chatPeerStatusProvider(otherId)).value ?? ChatPeerStatus.active;
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final contract = chat.relatedJobId == null ? null : ref.watch(contractForJobProvider(chat.relatedJobId!)).value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          SbAvatar(name: otherName, imageUrl: chat.otherPhoto(me.uid), size: 36),
          const SizedBox(width: SbSpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(otherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              if (chat.relatedJobTitle?.isNotEmpty ?? false)
                Text(chat.relatedJobTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ]),
        actions: [
          if (contract != null)
            IconButton(
              tooltip: l.chatViewContract,
              icon: const Icon(Icons.assignment_outlined),
              onPressed: () => context.push(RouteNames.contractDetailsLocation(contract.id), extra: contract),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SbReadableWidth(
          maxWidth: 840,
          child: Column(children: [
            if (!online)
              Padding(
                padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s2, SbLayout.edge(context), SbSpace.s2),
                child: SbOfflineNote(message: l.chatOffline),
              ),
            Expanded(child: _messages(chat, me, otherName)),
            if (peer == ChatPeerStatus.suspended)
              _Banner(message: l.chatPeerSuspended, tone: SbTone.neutral, icon: Icons.block_outlined)
            else
              _composer(me),
          ]),
        ),
      ),
    );
  }

  Widget _messages(ChatEntity chat, UserEntity me, String otherName) {
    final l = context.l10n;
    final async = ref.watch(chatMessagesProvider((chatId: widget.chatId, limit: _limit)));
    // Keep the previous page on screen while a larger page loads.
    if (async.hasValue) _shown = async.value;
    final messages = _shown;

    if (messages == null) {
      if (async.hasError) {
        return SbStateView(
          kind: SbStateKind.error,
          title: l.chatMessagesLoadError,
          message: l.errNetwork,
          actionLabel: l.tryAgain,
          onAction: () => ref.invalidate(chatMessagesProvider((chatId: widget.chatId, limit: _limit))),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final serverIds = {for (final m in messages) m.id};
    final pending = _outbox.values.where((o) => !serverIds.contains(o.id)).toList()..sort((a, b) => a.at.compareTo(b.at));
    if (messages.isEmpty && pending.isEmpty) {
      return SbStateView(
        kind: SbStateKind.empty,
        icon: Icons.waving_hand_outlined,
        title: l.chatEmptyTitle,
        message: l.chatEmptyBody(otherName),
      );
    }

    // Oldest → newest with day separators, then reversed for a list that
    // starts at the bottom (newest) and grows upwards.
    final items = <Widget>[];
    DateTime? lastDay;
    void day(DateTime at) {
      if (lastDay == null || !chatSameDay(lastDay!, at)) {
        items.add(_DaySeparator(label: chatDayLabel(context, at)));
        lastDay = at;
      }
    }

    final otherRead = chat.lastReadAt[chat.otherId(me.uid)];
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    // Status text only under my latest message (and any still sending).
    String? lastMineId;
    for (final m in messages) {
      if (m.senderId == me.uid) lastMineId = m.id;
    }
    for (final m in messages) {
      day(m.createdAt);
      if (m.type == MessageType.system) {
        items.add(_SystemNote(text: m.content));
        continue;
      }
      final mine = m.senderId == me.uid;
      final status = !mine
          ? null
          : m.isPending
              ? (online ? l.chatSending : l.chatWaitingNetwork)
              : (otherRead != null && !otherRead.isBefore(m.createdAt))
                  ? l.chatSeen
                  : l.chatSent;
      items.add(_Bubble(
        mine: mine,
        text: m.content,
        time: chatMessageTime(context, m.createdAt),
        status: status,
        showStatusText: mine && (m.isPending || m.id == lastMineId),
        pending: m.isPending,
        photos: [for (final p in m.attachments) _StoredPhoto(path: p)],
      ));
    }
    for (final o in pending) {
      day(o.at);
      items.add(_Bubble(
        mine: true,
        text: o.text,
        time: chatMessageTime(context, o.at),
        status: o.failed ? l.chatNotSent : (online ? l.chatSending : l.chatWaitingNetwork),
        showStatusText: true,
        pending: !o.failed,
        failed: o.failed,
        failureNote: o.failed && o.reason == ChatFailure.notAllowed ? l.chatNotAllowed : null,
        onRetry: o.failed ? () => _deliver(o, me) : null,
        onDiscard: o.failed ? () => setState(() => _outbox.remove(o.id)) : null,
        photos: [for (final p in o.photos) _LocalPhoto(bytes: p.bytes)],
      ));
    }

    final reversed = items.reversed.toList();
    final more = messages.length >= _limit;
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: SbLayout.edge(context), vertical: SbSpace.s3),
      itemCount: reversed.length + (more ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == reversed.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: SbSpace.s3),
            child: Center(
              child: SbButton(
                label: l.chatEarlier,
                variant: SbButtonVariant.quiet,
                size: SbButtonSize.compact,
                isLoading: async.isLoading,
                onPressed: async.isLoading ? null : () => setState(() => _limit += chatPageSize),
              ),
            ),
          );
        }
        return reversed[i];
      },
    );
  }

  Widget _composer(UserEntity me) {
    final l = context.l10n;
    final sb = context.sb;
    final canSend = _input.text.trim().isNotEmpty || _draftPhotos.isNotEmpty;
    return Container(
      decoration: BoxDecoration(color: sb.surface, border: Border(top: BorderSide(color: sb.border))),
      padding: EdgeInsets.fromLTRB(SbSpace.s2, SbSpace.s2, SbSpace.s2, SbSpace.s2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_draftPhotos.isNotEmpty)
          SizedBox(
            height: 76,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var i = 0; i < _draftPhotos.length; i++)
                Padding(
                  padding: const EdgeInsets.all(SbSpace.s1),
                  child: Stack(clipBehavior: Clip.none, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(SbRadius.control),
                      child: Image.memory(_draftPhotos[i].bytes, width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    PositionedDirectional(
                      top: -10,
                      end: -10,
                      child: IconButton(
                        tooltip: l.chatRemovePhoto,
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(backgroundColor: sb.surfaceRaised, side: BorderSide(color: sb.border)),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => setState(() => _draftPhotos.removeAt(i)),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          IconButton(
            tooltip: l.chatAddPhoto,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _draftPhotos.length >= chatMaxPhotos ? null : _addPhoto,
          ),
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 5,
              maxLength: chatMaxLength,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: l.chatInputHint,
                counterText: _input.text.length > chatMaxLength - 200 ? null : '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: SbSpace.s3, vertical: SbSpace.s3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(SbRadius.card)),
              ),
            ),
          ),
          const SizedBox(width: SbSpace.s1),
          IconButton.filled(
            tooltip: l.chatSend,
            icon: const Icon(Icons.send_rounded),
            onPressed: canSend ? () => _send(me) : null,
          ),
        ]),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.tone, this.icon});
  final String message;
  final SbTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s2, SbLayout.edge(context), SbSpace.s2),
        child: SbInlineBanner(message: message, tone: tone, icon: icon),
      );
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SbSpace.s3),
      child: Row(children: [
        Expanded(child: Divider(color: sb.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SbSpace.s3),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: sb.textSecondary)),
        ),
        Expanded(child: Divider(color: sb.border)),
      ]),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: SbSpace.s2),
        child: Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.mine,
    required this.text,
    required this.time,
    this.status,
    this.showStatusText = false,
    this.pending = false,
    this.failed = false,
    this.failureNote,
    this.onRetry,
    this.onDiscard,
    this.photos = const [],
  });

  final bool mine;
  final String text;
  final String time;
  final String? status;
  final bool showStatusText;
  final bool pending;
  final bool failed;
  final String? failureNote;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final List<Widget> photos;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    final fg = mine ? sb.onPrimary : sb.text;
    final meta = mine ? sb.onPrimary.withValues(alpha: 0.8) : sb.textSecondary;
    final icon = failed
        ? Icons.error_outline_rounded
        : pending
            ? Icons.schedule_rounded
            : status == l.chatSeen
                ? Icons.done_all_rounded
                : Icons.done_rounded;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Semantics(
      container: true,
      label: [mine ? l.chatYou : null, text.isNotEmpty ? text : l.chatPhoto, time, status].whereType<String>().join(', '),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth.clamp(200, 520)),
            child: Opacity(
              opacity: pending ? 0.85 : 1,
              child: Container(
                padding: const EdgeInsets.fromLTRB(SbSpace.s3, SbSpace.s2, SbSpace.s3, SbSpace.s2),
                decoration: BoxDecoration(
                  color: failed ? sb.errorSubtle : (mine ? sb.primary : sb.surface),
                  border: Border.all(color: failed ? sb.error : (mine ? sb.primary : sb.border)),
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(SbRadius.card),
                    topEnd: const Radius.circular(SbRadius.card),
                    bottomStart: Radius.circular(mine ? SbRadius.card : SbRadius.xs),
                    bottomEnd: Radius.circular(mine ? SbRadius.xs : SbRadius.card),
                  ),
                ),
                child: ExcludeSemantics(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    if (photos.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: text.isEmpty ? SbSpace.s1 : SbSpace.s2),
                        child: Wrap(spacing: SbSpace.s1, runSpacing: SbSpace.s1, children: photos),
                      ),
                    if (text.isNotEmpty) Text(text, style: t.bodyMedium!.copyWith(color: failed ? sb.onErrorSubtle : fg)),
                    const SizedBox(height: 2),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(time, style: t.labelSmall!.copyWith(color: failed ? sb.onErrorSubtle : meta)),
                      if (mine) ...[
                        const SizedBox(width: SbSpace.s1),
                        Icon(icon, size: 14, color: failed ? sb.error : meta),
                        if (showStatusText && status != null) ...[
                          const SizedBox(width: 2),
                          Text(status!, style: t.labelSmall!.copyWith(color: failed ? sb.onErrorSubtle : meta)),
                        ],
                      ],
                    ]),
                  ]),
                ),
              ),
            ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: SbSpace.s1),
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: SbSpace.s1, children: [
                if (failureNote != null) Text(failureNote!, style: t.bodySmall!.copyWith(color: sb.error)),
                if (onRetry != null)
                  SbButton(label: l.chatRetry, icon: Icons.refresh_rounded, variant: SbButtonVariant.quiet, size: SbButtonSize.compact, onPressed: onRetry),
                if (onDiscard != null)
                  SbButton(label: l.chatDiscard, variant: SbButtonVariant.quiet, size: SbButtonSize.compact, onPressed: onDiscard),
              ]),
            ),
        ]),
      ),
    );
  }
}

const double _photoSize = 160;

void _openPhoto(BuildContext context, Widget image) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        InteractiveViewer(child: image),
        PositionedDirectional(
          top: SbSpace.s2,
          end: SbSpace.s2,
          child: IconButton.filledTonal(
            tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ),
      ]),
    ),
  );
}

/// A photo kept privately in Firestore, read with the member's access — no link.
class _StoredPhoto extends ConsumerWidget {
  const _StoredPhoto({required this.path});
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sb = context.sb;
    final bytes = ref.watch(chatPhotoProvider(path));
    return ClipRRect(
      borderRadius: BorderRadius.circular(SbRadius.control),
      child: SizedBox(
        width: _photoSize,
        height: _photoSize,
        child: bytes.when(
          loading: () => const SbSkeleton(height: _photoSize, width: _photoSize, radius: SbRadius.control),
          error: (_, _) => _PhotoUnavailable(color: sb.surfaceSunken),
          data: (b) => b == null
              ? _PhotoUnavailable(color: sb.surfaceSunken)
              : Semantics(
                  button: true,
                  label: context.l10n.chatPhoto,
                  child: InkWell(
                    onTap: () => _openPhoto(context, Image.memory(b, fit: BoxFit.contain)),
                    child: Image.memory(b, fit: BoxFit.cover),
                  ),
                ),
        ),
      ),
    );
  }
}

class _LocalPhoto extends StatelessWidget {
  const _LocalPhoto({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(SbRadius.control),
        child: Image.memory(bytes, width: _photoSize, height: _photoSize, fit: BoxFit.cover),
      );
}

class _PhotoUnavailable extends StatelessWidget {
  const _PhotoUnavailable({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.broken_image_outlined, color: context.sb.textSecondary),
            const SizedBox(height: SbSpace.s1),
            Text(context.l10n.chatPhotoUnavailable, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
          ]),
        ),
      );
}
