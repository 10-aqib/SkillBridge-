import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/live_location_ui.dart';
import 'package:skill_bridge/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Directions to an accepted job (Navigation phase 9): the hired worker,
/// while the job is active, to the place the client pinned. Live-location
/// sharing can be switched on and off from the map, and on arrival the
/// worker can tell the client and start the work.
class ContractNavigationScreen extends ConsumerWidget {
  const ContractNavigationScreen({super.key, required this.contractId});
  final String contractId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
    final async = ref.watch(contractByIdProvider(contractId));
    final c = async.value;

    Widget message(String text, {SbStateKind kind = SbStateKind.error}) => Scaffold(
          appBar: AppBar(title: Text(l.navTitle)),
          body: SbStateView(kind: kind, title: text),
        );

    if (c == null) {
      if (async.isLoading) return Scaffold(appBar: AppBar(title: Text(l.navTitle)), body: const Center(child: CircularProgressIndicator()));
      return message(l.navJobLoadError);
    }
    // The rules already keep other people out of the contract; this keeps
    // the client (who can read it) from starting the worker's directions.
    if (uid == null || uid != c.workerId) return message(l.navOnlyWorker, kind: SbStateKind.permission);
    if (!liveLocationOpen(c)) return message(l.navJobClosed, kind: SbStateKind.empty);

    final label = (c.serviceAddress ?? '').trim().isNotEmpty ? c.serviceAddress!.trim() : c.jobTitle;
    return NavigationScreen(
      destination: c.serviceLocation,
      label: label,
      guidingAction: (_) => NavShareToggle(contract: c),
      arrivalActions: (_) => [NavArrivalActions(contract: c)],
    );
  }
}

/// Round map button to start or stop sharing the worker's live location
/// with the client, with the same consent as on the contract.
class NavShareToggle extends ConsumerWidget {
  const NavShareToggle({super.key, required this.contract});
  final ContractEntity contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sb = context.sb;
    final share = ref.watch(liveLocationControllerProvider);
    final sharing = share.contractId == contract.id && share.status == LiveShareStatus.sharing;
    final starting = share.contractId == contract.id && share.status == LiveShareStatus.starting;

    Future<void> toggle() async {
      final controller = ref.read(liveLocationControllerProvider.notifier);
      if (sharing) {
        await controller.stop();
        if (context.mounted) context.showSnackBar(l.liveStoppedNotice);
        return;
      }
      final ok = await showSbConfirmSheet(
        context,
        title: l.liveConsentTitle,
        message: l.liveConsentBody(contract.clientName),
        confirmLabel: l.liveConsentAgree,
        cancelLabel: l.liveNotNow,
      );
      if (!ok || !context.mounted) return;
      final status = await controller.start(contract.id);
      if (!context.mounted) return;
      if (status == LiveShareStatus.sharing) {
        context.showSnackBar(l.liveStartedNotice(contract.clientName));
        return;
      }
      final reason = switch (status) {
        LiveShareStatus.permissionDenied => l.livePermissionDenied,
        LiveShareStatus.permissionBlocked => l.livePermissionBlocked,
        LiveShareStatus.serviceOff => l.liveServiceOff,
        LiveShareStatus.unavailable => l.liveUnavailable,
        LiveShareStatus.ended => l.liveEnded,
        _ => l.liveError,
      };
      context.showSnackBar(reason, isError: true);
    }

    return Material(
      color: sharing ? sb.success : sb.surfaceRaised,
      shape: CircleBorder(side: BorderSide(color: sharing ? sb.success : sb.border)),
      elevation: 3,
      child: IconButton(
        tooltip: sharing ? l.liveStopSharing : l.liveStartSharing,
        isSelected: sharing,
        onPressed: starting ? null : toggle,
        icon: starting
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(sharing ? Icons.share_location_rounded : Icons.location_disabled_outlined, color: sharing ? sb.onSuccess : sb.primary),
      ),
    );
  }
}

/// On arrival: tell the client (a progress update, sent once) and start
/// the work if it hasn't started yet.
class NavArrivalActions extends ConsumerStatefulWidget {
  const NavArrivalActions({super.key, required this.contract});
  final ContractEntity contract;

  @override
  ConsumerState<NavArrivalActions> createState() => _NavArrivalActionsState();
}

class _NavArrivalActionsState extends ConsumerState<NavArrivalActions> {
  bool _sending = false;
  bool _sent = false;
  bool _starting = false;

  /// One request id for this arrival: retrying never posts twice.
  late final String _requestId = ref.read(contractActionsProvider).newRequestId();

  Future<void> _tell() async {
    final l = context.l10n;
    setState(() => _sending = true);
    try {
      await ref.read(contractActionsProvider).postProgressUpdate(widget.contract.id, requestId: _requestId, note: l.navArrivedNote);
      if (!mounted) return;
      setState(() => _sent = true);
      context.showSnackBar(l.navArrivedSent(widget.contract.clientName));
    } catch (_) {
      if (mounted) context.showSnackBar(l.navArrivedSendFailed, isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await ref.read(contractActionsProvider).startWork(widget.contract.id);
    } catch (_) {
      if (mounted) context.showSnackBar(context.l10n.navArrivedSendFailed, isError: true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // The live contract, so "Start work" disappears once started.
    final c = ref.watch(contractByIdProvider(widget.contract.id)).value ?? widget.contract;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      SbButton(
        label: _sent ? l.navArrivedSent(c.clientName) : l.navArrivedTell(c.clientName),
        icon: _sent ? Icons.check_rounded : Icons.campaign_outlined,
        expand: true,
        isLoading: _sending,
        onPressed: _sent || _sending ? null : _tell,
      ),
      if (c.stage == ContractStage.notStarted) ...[
        const SizedBox(height: SbSpace.s2),
        SbButton(
          label: l.contractStart,
          icon: Icons.play_arrow_rounded,
          variant: SbButtonVariant.secondary,
          expand: true,
          isLoading: _starting,
          onPressed: _starting ? null : _start,
        ),
      ],
    ]);
  }
}
