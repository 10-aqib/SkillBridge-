import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/map/map_markers.dart';
import 'package:skill_bridge/core/map/sb_map.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/models/live_location.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/live_location_ui.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';
import 'package:skill_bridge/features/navigation/domain/entities/nav_route.dart';
import 'package:skill_bridge/features/navigation/domain/route_geometry.dart';
import 'package:skill_bridge/features/navigation/presentation/nav_text.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/routing_providers.dart';
import 'package:skill_bridge/features/navigation/presentation/widgets/route_layer.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The client following the hired worker (Navigation phase 9): their live
/// position (and direction while moving), the pinned place, the road route
/// from them with distance and time left. Only positions updated in the
/// last two minutes count as live; older ones are dimmed, marked "not
/// live", and get no route or arrival time.
class ContractTrackingScreen extends ConsumerStatefulWidget {
  const ContractTrackingScreen({super.key, required this.contractId});
  final String contractId;

  /// A new road route is asked for after the worker moves this far from
  /// where the last one started, or after [routeMaxAge].
  static const rerouteAfterMetres = 150.0;
  static const routeMaxAge = Duration(minutes: 2);

  /// Within this straight distance of the pin the worker counts as there.
  static const arrivedWithin = 60.0;

  @override
  ConsumerState<ContractTrackingScreen> createState() => _ContractTrackingScreenState();
}

class _ContractTrackingScreenState extends ConsumerState<ContractTrackingScreen> {
  final _map = MapController();
  bool _ready = false;
  bool _follow = true;
  Timer? _tick;

  NavRoute? _route;
  RouteLine? _line;
  LatLng? _routeFrom;
  DateTime? _routeAt;
  bool _routing = false;
  bool _routeFailed = false;

  @override
  void initState() {
    super.initState();
    // Re-checks freshness so a position turns "not live" on time.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _map.dispose();
    super.dispose();
  }

  bool _isLive(LiveLocation? loc) => loc != null && loc.isLive(DateTime.now()) && (ref.read(connectivityStatusProvider).value ?? true);

  void _frame(LiveLocation? loc, LatLng? pin) {
    if (!_ready) return;
    _map.frame([
      if (loc != null) LatLng(loc.lat, loc.lng),
      ?pin,
    ], padding: const EdgeInsets.fromLTRB(64, 64, 64, 260), maxZoom: 16);
  }

  /// Asks for the road route from the worker when there is none yet, they
  /// moved far from where it started, or it is old. Never for a stale position.
  Future<void> _maybeRoute(LiveLocation loc, LatLng pin) async {
    if (_routing || !_isLive(loc)) return;
    final from = LatLng(loc.lat, loc.lng);
    final moved = _routeFrom == null ? double.infinity : const Distance().as(LengthUnit.Meter, _routeFrom!, from);
    final old = _routeAt == null || DateTime.now().difference(_routeAt!) > ContractTrackingScreen.routeMaxAge;
    if (_route != null && moved < ContractTrackingScreen.rerouteAfterMetres && !old) return;
    if (_route == null && _routeFailed && !old) return; // wait before retrying
    _routing = true;
    try {
      final result = await ref.read(routingServiceProvider).getRoute(from, pin, alternatives: false);
      if (!mounted) return;
      setState(() {
        _route = result.primary;
        _line = RouteLine(result.primary.points);
        _routeFrom = from;
        _routeAt = DateTime.now();
        _routeFailed = false;
      });
    } on RoutingException {
      if (!mounted) return;
      setState(() {
        _routeFailed = true;
        _routeAt = DateTime.now();
      });
    } finally {
      _routing = false;
    }
  }

  void _onLive(LiveLocation? loc, ContractEntity c) {
    if (loc == null) return;
    if (_follow) _frame(loc, c.serviceLocation);
    final pin = c.serviceLocation;
    if (pin != null) _maybeRoute(loc, pin);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final uid = ref.watch(currentUserProvider.select((u) => u?.uid));
    final async = ref.watch(contractByIdProvider(widget.contractId));
    final c = async.value;

    Widget message(String text, {SbStateKind kind = SbStateKind.error}) => Scaffold(
          appBar: AppBar(title: Text(l.trackTitle)),
          body: SbStateView(kind: kind, title: text),
        );
    if (c == null) {
      if (async.isLoading) return Scaffold(appBar: AppBar(title: Text(l.trackTitle)), body: const Center(child: CircularProgressIndicator()));
      return message(l.navJobLoadError);
    }
    if (uid == null || uid != c.clientId) return message(l.trackOnlyClient, kind: SbStateKind.permission);
    if (!liveLocationOpen(c)) return message(l.navJobClosed, kind: SbStateKind.empty);

    ref.listen<AsyncValue<LiveLocation?>>(contractLiveLocationProvider(c.id), (previous, next) => _onLive(next.value, c));
    final liveAsync = ref.watch(contractLiveLocationProvider(c.id));
    final loc = liveAsync.value;
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final live = _isLive(loc);
    final pin = c.serviceLocation;
    final here = loc == null ? null : LatLng(loc.lat, loc.lng);

    // Distance and time left along the current route, from the latest
    // position (no new request for every move).
    double? leftMetres;
    double? leftSeconds;
    final line = _line;
    if (live && here != null && _route != null && line != null) {
      final snap = line.snap(here);
      if (snap.distanceToRoute < 300) {
        leftMetres = line.remainingFrom(snap);
        leftSeconds = remainingDurationAt(_route!, snap.distanceAlong);
      }
    }
    final atPlace = live && here != null && pin != null && const Distance().as(LengthUnit.Meter, here, pin) <= ContractTrackingScreen.arrivedWithin;

    return Scaffold(
      appBar: AppBar(title: Text(l.trackTitle)),
      body: Stack(children: [
        Positioned.fill(
          child: SbMap(
            controller: _map,
            initialCenter: here ?? pin ?? const LatLng(30.3753, 69.3451),
            initialZoom: here != null || pin != null ? 14 : 5,
            onMapReady: () {
              _ready = true;
              _onLive(loc, c);
            },
            onRecenter: here == null && pin == null
                ? null
                : () {
                    setState(() => _follow = true);
                    _frame(loc, pin);
                  },
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
            layers: [
              if (live && _route != null && !atPlace) SbRouteLayer(route: _route!),
              if (loc != null && (loc.accuracy ?? 0) > 0 && (loc.accuracy ?? 0) < 2000)
                CircleLayer(circles: [sbAccuracyCircle(context, here!, loc.accuracy!)]),
              MarkerLayer(markers: [
                if (pin != null) sbDestinationMarker(pin, semanticLabel: l.contractPinTitle),
                if (here != null) sbPersonMarker(here, name: c.workerName, stale: !live, heading: live ? loc!.heading : null),
              ]),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _TrackingPanel(
            contract: c,
            location: loc,
            loading: loc == null && liveAsync.isLoading,
            failed: loc == null && liveAsync.hasError,
            onRetry: () => ref.invalidate(contractLiveLocationProvider(c.id)),
            live: live,
            online: online,
            leftMetres: leftMetres,
            leftSeconds: leftSeconds,
            atPlace: atPlace,
            routeFailed: _routeFailed && _route == null,
          ),
        ),
      ]),
    );
  }
}

class _TrackingPanel extends StatelessWidget {
  const _TrackingPanel({
    required this.contract,
    required this.location,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.live,
    required this.online,
    required this.leftMetres,
    required this.leftSeconds,
    required this.atPlace,
    required this.routeFailed,
  });

  final ContractEntity contract;
  final LiveLocation? location;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final bool live;
  final bool online;
  final double? leftMetres;
  final double? leftSeconds;
  final bool atPlace;
  final bool routeFailed;

  String _ago(BuildContext context, DateTime at) {
    final l = context.l10n;
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 45) return l.liveJustNow;
    if (d.inMinutes < 60) return l.liveMinutesAgo(d.inMinutes.clamp(1, 59));
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ur' ? DateFormat.Hm('ur').format(at) : DateFormat.jm(locale.toLanguageTag()).format(at);
  }

  String _clock(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ur' ? DateFormat.Hm('ur').format(at) : DateFormat.jm(locale.toLanguageTag()).format(at);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    final c = contract;
    final loc = location;

    final children = <Widget>[];
    if (loading) {
      children.add(const Center(child: Padding(padding: EdgeInsets.all(SbSpace.s3), child: CircularProgressIndicator())));
    } else if (failed) {
      children.add(SbInlineBanner(message: l.liveLoadError, tone: SbTone.error, actionLabel: l.tryAgain, onAction: onRetry));
    } else if (loc == null) {
      children.add(Row(children: [
        Icon(Icons.location_off_outlined, color: sb.textSecondary),
        const SizedBox(width: SbSpace.s2),
        Expanded(child: Text(l.liveClientNotSharing(c.workerName), style: t.bodyLarge)),
      ]));
    } else {
      children.add(Row(children: [
        Expanded(child: Text(c.workerName, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
        live
            ? SbStatusBadge(label: l.liveBadge, icon: Icons.circle, tone: SbTone.success)
            : SbStatusBadge(label: l.liveBadgeStale, icon: Icons.history_rounded, tone: SbTone.warning),
      ]));
      children.add(Text(
        [
          l.liveUpdated(_ago(context, loc.updatedAt ?? DateTime.now())),
          if (loc.accuracy != null) l.liveAccuracy(loc.accuracy!.round()),
        ].join(' · '),
        style: t.bodySmall,
      ));
      children.add(const SizedBox(height: SbSpace.s2));
      if (!live) {
        children.add(SbInlineBanner(message: online ? l.liveClientStale(c.workerName) : l.liveClientOffline, tone: SbTone.warning));
      } else if (atPlace) {
        children.add(SbInlineBanner(message: l.trackArrived(c.workerName), tone: SbTone.success));
      } else if (c.serviceLocation == null) {
        children.add(Text(l.trackNoPin, style: t.bodyMedium));
      } else if (leftMetres != null && leftSeconds != null) {
        children.add(Text(
          l.trackRoadLeft(formatNavDistance(l, leftMetres!), formatNavDuration(l, leftSeconds!)),
          style: SbTypography.numeric(t.titleMedium!).copyWith(color: sb.success, fontWeight: FontWeight.w700),
        ));
        children.add(Text(l.trackArriveAbout(_clock(context, DateTime.now().add(Duration(seconds: leftSeconds!.round())))), style: t.bodyMedium));
        children.add(Text(l.navEstimateNote, style: t.bodySmall));
      } else if (routeFailed) {
        children.add(Text(l.trackNoRoute, style: t.bodyMedium));
      }
    }

    return Material(
      color: sb.surface,
      elevation: 12,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SbRadius.sheet)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(SbSpace.s4),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ),
    );
  }
}
