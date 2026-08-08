import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/notifications/data/models/notification_model.dart';
import 'package:skill_bridge/features/notifications/presentation/providers/notification_providers.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_empty_state.dart';

/// Guild Modernist Notification Screen
class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: Text(
          'Notifications • اطلاعات',
          style: AppTextStyles.heading3.copyWith(color: AppColors.onSurface),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.onSurface),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: userAsync == null
          ? Center(
              child: Text(
                'Please log in to see notifications.',
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.onSurfaceVariant,
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
          'Could not load notifications: $e',
          style:
              AppTextStyles.bodyPrimary.copyWith(color: AppColors.errorRed),
        ),
      ),
      data: (notifications) {
        if (notifications.isEmpty) {
          return const AppEmptyState(
            title: 'No Notifications Yet • کوئی اطلاع نہیں',
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
              onTap: () => _onNotifTap(ref, notif),
            ).animate().fade(delay: (60 * index).ms, duration: 350.ms);
          },
        );
      },
    );
  }

  Future<void> _onNotifTap(WidgetRef ref, NotificationModel notif) async {
    if (!notif.isRead) {
      final datasource = ref.read(notificationRemoteDataSourceProvider);
      await datasource.markAsRead(notif.id);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final timeStr = DateFormat('MMM d • h:mm a').format(notification.createdAt);

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
                    : AppColors.backgroundGray,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(notification.payload?['type'] as String?),
                size: 20,
                color: isUnread
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
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
                                  color: AppColors.onSurface,
                                )
                              : AppTextStyles.bodyPrimary.copyWith(
                                  color: AppColors.onSurface,
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
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodyPrimary.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: AppTextStyles.dataNumeric.copyWith(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
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
        return Icons.chat_bubble_outline_rounded;
      case 'payment':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
