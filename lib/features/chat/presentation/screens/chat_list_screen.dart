import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/language_provider.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';

/// Guild Modernist Chat List Screen — Premium Design
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsStreamProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isUrdu = ref.watch(languageProvider).languageCode == 'ur';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF001E60), Color(0xFF1A56DB)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isUrdu ? 'پیغامات' : 'Messages',
                          style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isUrdu
                              ? 'اپنی گفتگو اور پیغامات یہاں دیکھیں'
                              : 'Keep track of your conversations',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          chatsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    Text(
                      isUrdu ? 'پیغامات لوڈ نہیں ہو سکے' : 'Could not load messages',
                      style: AppTextStyles.heading3.copyWith(color: context.textColor),
                    ),
                  ],
                ),
              ),
            ),
            data: (chats) {
              if (chats.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 44, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                            isUrdu ? 'کوئی پیغام نہیں' : 'No Conversations Yet',
                            style: AppTextStyles.heading3
                                .copyWith(color: context.textColor)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            isUrdu ? 'کسی ورکر یا کلائنٹ سے رابطہ شروع کریں' : 'Start a conversation by reaching out to someone.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.push(RouteNames.clientNearbyWorkersPath),
                          icon: const Icon(Icons.explore_rounded),
                          label: Text(isUrdu ? 'ورکرز تلاش کریں' : 'Browse Services'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = chats[index];
                      final otherUserId = chat.participantIds.firstWhere(
                          (id) => id != currentUser?.uid,
                          orElse: () => '');
                      final otherName = chat.participantNames[otherUserId] ?? 'Unknown';
                      final otherPhoto = chat.participantPhotos[otherUserId];
                      final unread = chat.unreadCount[currentUser?.uid ?? ''] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => context.push(
                            RouteNames.chatRoomPath.replaceFirst(':chatId', chat.id),
                            extra: chat,
                          ),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppDimensions.md),
                            shadow: AppShadows.level1,
                            child: Row(
                              children: [
                                AppAvatar(
                                  name: otherName,
                                  imageUrl: otherPhoto,
                                  size: 56,
                                ),
                                const SizedBox(width: AppDimensions.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        otherName,
                                        style: AppTextStyles.heading3.copyWith(
                                          color: context.textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chat.lastMessage.isEmpty
                                            ? (isUrdu ? 'ابھی کوئی پیغام نہیں' : 'No messages yet')
                                            : chat.lastMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: unread > 0 ? context.textColor : AppColors.onSurfaceVariant,
                                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatTime(chat.lastMessageAt, isUrdu),
                                      style: AppTextStyles.labelCaption.copyWith(
                                        color: unread > 0 ? AppColors.primary : AppColors.onSurfaceVariant,
                                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (unread > 0) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$unread',
                                          style: AppTextStyles.labelCaption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: (60 * index).ms, duration: 350.ms),
                      );
                    },
                    childCount: chats.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt, bool isUrdu) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return isUrdu ? 'ابھی' : 'Just now';
    if (diff.inHours < 1) return isUrdu ? '${diff.inMinutes} منٹ قبل' : '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return isUrdu ? '${diff.inHours} گھنٹے قبل' : '${diff.inHours}h ago';
    return isUrdu ? '${diff.inDays} دن قبل' : '${diff.inDays}d ago';
  }
}
