import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/map/maps_api.dart';
import 'package:skill_bridge/core/map/maps_config.dart';
import 'package:skill_bridge/core/map/maps_links.dart';
import 'package:skill_bridge/core/map/route_format.dart';
import 'package:skill_bridge/core/map/sb_google_map.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/live_location_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Directions to an accepted job: the hired worker, while the job is
/// active, to the place the client pinned. Driving directions open in
/// Google Maps (the app has no turn-by-turn guidance of its own).
/// Live-location sharing can be switched on and off here, and on arrival
/// the worker can tell the client and start the work.
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
    final dest = c.serviceLocation;
    final hasDest = dest != null && dest.isValid;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;

    return Scaffold(
      appBar: AppBar(title: Text(l.navTitle), actions: [
        Padding(padding: const EdgeInsetsDirectional.only(end: SbSpace.s3), child: NavShareToggle(contract: c)),
      ]),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: hasDest
              ? _DirectionsMap(destination: dest, label: label)
              // No pin yet: the panel below explains it.
              : ColoredBox(color: sb.surfaceSunken, child: Center(child: Icon(Icons.location_off_outlined, size: 40, color: sb.textSecondary))),
        ),
        Material(
          color: sb.surface,
          elevation: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(SbRadius.sheet)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(SbSpace.s4),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.place_rounded, color: sb.accent),
                  const SizedBox(width: SbSpace.s3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.navRouteTo(label), style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (hasDest)
                        Text('${dest.latitude.toStringAsFixed(5)}, ${dest.longitude.toStringAsFixed(5)}',
                            style: SbTypography.numeric(t.bodySmall!), textDirection: TextDirection.ltr)
                      else
                        Text(l.navErrNoDestination, style: t.bodySmall),
                    ]),
                  ),
                ]),
                if (hasDest) _RouteLine(destination: dest),
                const SizedBox(height: SbSpace.s3),
                SbButton(
                  label: l.navOpenGoogleMaps,
                  icon: Icons.directions_rounded,
                  expand: true,
                  onPressed: hasDest ? () => GoogleMapsLinks.open(GoogleMapsLinks.directions(dest)) : null,
                ),
                const SizedBox(height: SbSpace.s2),
                NavArrivalActions(contract: c),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// The worker's road route to [destination] from where they are now, when
/// location is already allowed (this screen never asks for it; the Google
/// Maps button covers driving without it). Null when there is no position
/// or the maps server isn't set up.
final directionsRouteProvider = FutureProvider.autoDispose.family<({RouteSummary route, GeoCoord from})?, GeoCoord>((ref, destination) async {
  final api = ref.watch(mapsApiProvider);
  if (!api.available) return null;
  if (!await ref.watch(mapMyLocationAllowedProvider.future)) return null;
  final GeoFix fix;
  try {
    fix = await ref.watch(locationSourceProvider).current(timeLimit: const Duration(seconds: 15), profile: LocationProfile.display);
  } catch (_) {
    return null;
  }
  if (!fix.isValid) return null;
  return (route: await api.route(fix.point, destination), from: fix.point);
});

class _DirectionsMap extends ConsumerStatefulWidget {
  const _DirectionsMap({required this.destination, required this.label});
  final GeoCoord destination;
  final String label;

  @override
  ConsumerState<_DirectionsMap> createState() => _DirectionsMapState();
}

class _DirectionsMapState extends ConsumerState<_DirectionsMap> {
  SbMapController? _map;

  void _frame(({RouteSummary route, GeoCoord from})? r) {
    _map?.fit([widget.destination, if (r != null) ...[r.from, ...r.route.points]], padding: 64, maxZoom: 16);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(directionsRouteProvider(widget.destination), (_, next) => _frame(next.value));
    final r = ref.watch(directionsRouteProvider(widget.destination)).value;
    return SbGoogleMap(
      initialCenter: widget.destination,
      initialZoom: 15,
      showMyLocation: true,
      showZoomButtons: true,
      onCreated: (m) {
        _map = m;
        if (r != null) _frame(r);
      },
      onRecenter: () => _frame(ref.read(directionsRouteProvider(widget.destination)).value),
      polylines: [if (r != null) SbPolyline(id: 'route', points: r.route.points)],
      markers: [SbMarker(id: 'destination', position: widget.destination, kind: SbMarkerKind.destination, title: widget.label)],
    );
  }
}

/// "4.2 km by road · about 13 min", or why there's no route.
class _RouteLine extends ConsumerWidget {
  const _RouteLine({required this.destination});
  final GeoCoord destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final async = ref.watch(directionsRouteProvider(destination));
    final String? text;
    TextStyle? style = t.bodySmall;
    if (async.isLoading) {
      text = ref.read(mapsApiProvider).available ? l.navCalculating : null;
    } else if (async.hasError) {
      final f = async.error is MapsApiException ? (async.error as MapsApiException).failure : MapsApiFailure.failed;
      text = switch (f) {
        MapsApiFailure.noRoute => l.navErrNoRoute,
        MapsApiFailure.offline => l.navErrOffline,
        MapsApiFailure.notAvailable => null,
        _ => l.navErrRouting,
      };
    } else if (async.value != null) {
      final r = async.value!.route;
      text = l.trackRoadLeft(formatRouteDistance(l, r.distanceMeters), formatRouteDuration(l, r.durationSeconds));
      style = SbTypography.numeric(t.titleSmall!).copyWith(color: sb.success, fontWeight: FontWeight.w700);
    } else {
      text = null;
    }
    if (text == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: SbSpace.s2), child: Text(text, style: style));
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
      // The button itself now says it was sent (no snack bar over the
      // "Start work" button).
      setState(() => _sent = true);
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
