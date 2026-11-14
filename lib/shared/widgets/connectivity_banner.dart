import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/firestore_outbox_sync_engine.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';

/// Shows connectivity and pending-write state above routed screens.
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityStatusProvider);
    final pendingCount = ref
        .watch(pendingOutboxCountProvider)
        .when(data: (count) => count, loading: () => 0, error: (_, __) => 0);

    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
      final wasConnected = previous?.when(
        data: (connected) => connected,
        loading: () => null,
        error: (_, __) => null,
      );
      final isConnected = next.when(
        data: (connected) => connected,
        loading: () => null,
        error: (_, __) => null,
      );
      if (isConnected == true && wasConnected != true) {
        unawaited(FirestoreOutboxSyncEngine().syncPendingItems());
      }
    });

    final isOffline = status.when(
      data: (isConnected) => !isConnected,
      loading: () => false,
      error: (_, __) => true,
    );
    final showStatus = isOffline || pendingCount > 0;

    final String messageEn = isOffline
        ? pendingCount > 0
            ? 'No internet connection. $pendingCount saved action${pendingCount == 1 ? '' : 's'} will sync when you reconnect.'
            : 'No internet connection. Some features may be unavailable.'
        : '$pendingCount saved action${pendingCount == 1 ? '' : 's'} waiting to sync.';

    final String messageUr = isOffline
        ? pendingCount > 0
            ? 'انٹرنیٹ نہیں ہے۔ $pendingCount ایکشن محفوظ ہیں اور دوبارہ آن لائن ہونے پر سنک ہوں گے۔'
            : 'انٹرنیٹ کنکشن موجود نہیں ہے۔ کچھ فیچرز دستیاب نہیں ہو سکتے۔'
        : '$pendingCount ایکشن سنک ہونے کے منتظر ہیں۔';

    final isDark = context.isDark;
    final bannerBg = isOffline
        ? (isDark ? const Color(0xFF261C08) : const Color(0xFFFEF3C7))
        : (isDark ? const Color(0xFF0F1D38) : const Color(0xFFEBF2FF));

    final borderBottomColor = isOffline
        ? (isDark
            ? AppColors.amberWarm.withValues(alpha: 0.4)
            : AppColors.amberWarm.withValues(alpha: 0.6))
        : (isDark
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.primary.withValues(alpha: 0.3));

    final iconColor = isOffline
        ? AppColors.amberWarm
        : (isDark ? AppColors.inversePrimary : AppColors.primary);

    final bannerTextColor = isDark
        ? const Color(0xFFF3F4F6)
        : (isOffline ? const Color(0xFF78350F) : const Color(0xFF1E3A8A));

    final buttonBgColor = isOffline
        ? AppColors.amberWarm.withValues(alpha: isDark ? 0.25 : 0.20)
        : AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15);

    final buttonTextColor = isOffline
        ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
        : (isDark ? const Color(0xFF93C5FD) : AppColors.primary);

    final overlayStyle = isDark || !isOffline
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          child: showStatus
              ? AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlayStyle,
                  child: Material(
                    color: bannerBg,
                    elevation: 1,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: SafeArea(
                        bottom: false,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.md,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: borderBottomColor,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isOffline
                                    ? Icons.wifi_off_rounded
                                    : Icons.cloud_upload_outlined,
                                color: iconColor,
                                size: 18,
                              ),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(
                                child: Text(
                                  AppL10n.select(
                                    context,
                                    en: messageEn,
                                    ur: messageUr,
                                  ),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: bannerTextColor,
                                    fontSize: 12.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.sm),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(48, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: buttonBgColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: isOffline
                                    ? () => ref.invalidate(
                                          connectivityStatusProvider,
                                        )
                                    : () => unawaited(
                                          FirestoreOutboxSyncEngine()
                                              .syncPendingItems(),
                                        ),
                                child: Text(
                                  AppL10n.select(
                                    context,
                                    en: isOffline ? 'Retry' : 'Sync now',
                                    ur: isOffline
                                        ? 'دوبارہ کوشش'
                                        : 'ابھی سنک کریں',
                                  ),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: buttonTextColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: showStatus
              ? MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: child,
                )
              : child,
        ),
      ],
    );
  }
}
