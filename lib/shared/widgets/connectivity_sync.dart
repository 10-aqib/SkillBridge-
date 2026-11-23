import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/services/firestore_outbox_sync_engine.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// App-wide connection handling, above every screen:
/// * while the device is offline, one plain line at the top says so ("You're
///   offline"), in the normal text colour on the normal background: black on
///   white in light mode. It replaced the old yellow warning bar, at the
///   owner's request;
/// * when the connection comes back, actions saved while offline (for example
///   a job posted without internet) are sent.
class ConnectivitySync extends ConsumerWidget {
  const ConnectivitySync({super.key, required this.child, this.onReconnect});

  final Widget child;

  /// Test hook; defaults to sending the outbox.
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (previous, next) {
      final wasConnected = previous?.value;
      final isConnected = next.value;
      if (isConnected == true && wasConnected != true) {
        (onReconnect ?? () => unawaited(FirestoreOutboxSyncEngine().syncPendingItems()))();
      }
    });
    final offline = ref.watch(connectivityStatusProvider).value == false;
    final mq = MediaQuery.of(context);

    // The tree below keeps the same shape whether or not the line shows, so
    // the screens (and the navigation stack) are never rebuilt from scratch.
    return Column(children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: offline ? const OfflineLine() : const SizedBox(width: double.infinity),
      ),
      Expanded(
        child: MediaQuery(
          // The line already covers the status bar area.
          data: offline ? mq.removePadding(removeTop: true).removeViewPadding(removeTop: true) : mq,
          child: child,
        ),
      ),
    ]);
  }
}

/// The "You're offline" line itself.
class OfflineLine extends StatelessWidget {
  const OfflineLine({super.key});

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Material(
        color: sb.surface,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: SbSpace.s4, vertical: SbSpace.s2),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sb.border))),
            child: Semantics(
              liveRegion: true,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.cloud_off_rounded, size: 16, color: offlineInk(context)),
                const SizedBox(width: SbSpace.s2),
                Flexible(
                  child: Text(
                    context.l10n.offlineNow,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: offlineInk(context), fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
