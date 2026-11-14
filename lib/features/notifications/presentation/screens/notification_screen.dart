import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/features/notifications/presentation/notification_routes.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';
import 'package:skill_bridge/features/notifications/presentation/providers/notification_providers.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_empty_state.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

/// Guild Modernist Notification Screen
class NotificationScreen extends ConsumerWidget {
  NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          AppL10n.select(context, en: 'Notifications', ur: 'اطلاعات'),
          style: AppTextStyles.heading3.copyWith(color: context.textColor),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: context.canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: context.textColor),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: userAsync == null
          ? Center(
              child: Text(
                'Please log in to see notifications.',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: context.mutedColor,
                ),
              ),
            )
          : _NotificationList(userId: userAsync.uid),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  final String userId;
  const _NotificationList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(
      userNotificationsStreamProvider(userId),
    );

    return notificationsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          context.l10n.errNetwork,
          style:
              AppTextStyles.bodyPrimary.copyWith(color: AppColors.errorRed),
        ),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return AppEmptyState(
            title: AppL10n.select(context, en: 'No Notifications Yet', ur: 'کوئی اطلاع نہیں'),
            description: 'We\'ll notify you when something important happens.',
            icon: Icons.notifications_none_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.lg),
          itemCount: notifications.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return _NotificationTile(
              notification: notif,
              onTap: () => _onNotifTap(context, ref, notif),
            ).animate().fade(delay: (60 * index).ms, duration: 350.ms);
          },
        );
      },
    );
  }

  /// Marks it read and opens what it is about: the conversation for a
  /// message, the contract for a contract update. The opened screen checks
  /// access itself (the rules allow only the two members/parties).
  Future<void> _onNotifTap(BuildContext context, WidgetRef ref, NotificationModel notif) async {
    if (!notif.isRead) {
      final datasource = ref.read(notificationRemoteDataSourceProvider);
      datasource.markAsRead(notif.id).catchError((_) {});
    }
    if (!context.mounted) return;
    final route = notificationRouteFor(notif.payload, type: notif.type);
    if (route != null) context.push(route);
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final timeStr = DateFormat(AppL10n.select(context, en: 'MMM d', ur: 'h:mm a')).format(notification.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: AppCard(
        padding: const EdgeInsets.all(AppDimensions.md),
        shadow: AppShadows.level1,
        leftAccentColor: isUnread ? AppColors.primary : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : context.scaffoldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(notification.type),
                size: 20,
                color: isUnread
                    ? AppColors.primary
                    : context.mutedColor,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: isUnread
                              ? AppTextStyles.bodyStrong.copyWith(
                                  color: context.textColor,
                                )
                              : AppTextStyles.bodyPrimary.copyWith(
                                  color: context.textColor,
                                ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: context.mutedColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: AppTextStyles.dataNumeric.copyWith(
                      fontSize: 11,
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'proposal':
        return Icons.description_outlined;
      case 'contract':
        return Icons.handshake_outlined;
      case 'review':
        return Icons.star_outline_rounded;
      case 'chat':
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'contract_created':
      case 'work_started':
      case 'address_shared':
        return Icons.handshake_outlined;
      case 'work_submitted':
      case 'completion_confirmed':
        return Icons.task_alt_rounded;
      case 'revision_requested':
        return Icons.replay_rounded;
      case 'progress_update':
        return Icons.update_rounded;
      case 'payment':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
