import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/features/chat/data/models/chat_model.dart';
import 'package:skill_bridge/features/chat/data/models/message_model.dart';

/// Guild Modernist Chat Room Screen
class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatModel chat;

  const ChatRoomScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid != null) {
      ref.read(chatRemoteDataSourceProvider).markAsRead(widget.chat.id, uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final message = MessageModel(
      id: '',
      chatId: widget.chat.id,
      senderId: user.uid,
      senderName: user.displayName,
      senderPhotoUrl: user.photoUrl,
      content: text,
      type: MessageType.text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    ref.read(chatRemoteDataSourceProvider).sendMessage(message);
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendVoiceNote() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chat.id,
      senderId: user.uid,
      senderName: user.displayName,
      senderPhotoUrl: user.photoUrl,
      content: '[Voice Note — 0:24 • آواز کا پیغام]',
      type: MessageType.text,
      isRead: false,
      createdAt: DateTime.now(),
    );
    ref.read(chatRemoteDataSourceProvider).sendMessage(message);
    context.showSnackBar('🎤 Voice note sent to worker.');
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesStreamProvider(widget.chat.id));
    final currentUser = ref.watch(currentUserProvider);

    final otherUserId = widget.chat.participantIds
        .firstWhere((id) => id != currentUser?.uid, orElse: () => '');
    final otherName = widget.chat.participantNames[otherUserId] ?? 'Chat';

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherName,
              style:
                  AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
            ),
            if (widget.chat.relatedJobTitle != null)
              Text(
                widget.chat.relatedJobTitle!,
                style: AppTextStyles.labelCaption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message List ─────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text(
                  err.toString(),
                  style: AppTextStyles.bodyPrimary
                      .copyWith(color: AppColors.errorRed),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello! 👋 • السلام علیکم',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isOwn = msg.senderId == currentUser?.uid;
                    return _MessageBubble(
                      message: msg,
                      isOwn: isOwn,
                    ).animate().fade(duration: 250.ms);
                  },
                );
              },
            ),
          ),

          // ── Text Input Bar ────────────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.lg,
                vertical: AppDimensions.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                border: Border(
                  top: BorderSide(
                    color: AppColors.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.bodyPrimary.copyWith(
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message • پیغام لکھیں...',
                        hintStyle: AppTextStyles.bodyPrimary.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.backgroundGray,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.lg,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  GestureDetector(
                    onTap: _sendVoiceNote,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.level1,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isOwn;

  const _MessageBubble({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: context.screenWidth * 0.72,
        ),
        decoration: BoxDecoration(
          color: isOwn ? AppColors.primary : AppColors.surfaceWhite,
          border: isOwn
              ? null
              : Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusLg),
            topRight: const Radius.circular(AppDimensions.radiusLg),
            bottomLeft: Radius.circular(isOwn ? AppDimensions.radiusLg : 4),
            bottomRight: Radius.circular(isOwn ? 4 : AppDimensions.radiusLg),
          ),
          boxShadow: AppShadows.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.startsWith('[Voice Note')) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: isOwn ? AppColors.onPrimary : AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Note • آواز کا پیغام',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isOwn ? AppColors.onPrimary : AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            for (int i = 0; i < 12; i++)
                              Container(
                                width: 3,
                                height: (i % 3 == 0) ? 14 : ((i % 2 == 0) ? 8 : 18),
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                  color: (isOwn ? AppColors.onPrimary : AppColors.primary)
                                      .withValues(alpha: i > 7 ? 0.4 : 0.9),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '0:24',
                              style: AppTextStyles.dataNumeric.copyWith(
                                fontSize: 11,
                                color: isOwn ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                message.content,
                style: AppTextStyles.bodyPrimary.copyWith(
                  color: isOwn ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: AppTextStyles.dataNumeric.copyWith(
                fontSize: 11,
                color: isOwn
                    ? AppColors.onPrimary.withValues(alpha: 0.8)
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
