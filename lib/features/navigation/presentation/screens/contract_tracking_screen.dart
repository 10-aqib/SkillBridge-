import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/location/geo_coord.dart';
import 'package:skill_bridge/core/map/maps_api.dart';
import 'package:skill_bridge/core/map/maps_links.dart';
import 'package:skill_bridge/core/map/route_format.dart';
import 'package:skill_bridge/core/map/sb_google_map.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/data/models/live_location.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/widgets/live_location_ui.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// The client following the hired worker (Navigation phase 9; Google Maps
/// since G2, road routes since G3): their live position on the map with the
/// pinned place, the road route from them with distance and time, and
/// whether they have arrived. Only positions updated in the last two minutes
/// count as live; older ones are marked "not live" and get no route or time.
class ContractTrackingScreen extends ConsumerStatefulWidget {
  const ContractTrackingScreen({super.key, required this.contractId});
  final String contractId;

  /// Within this straight distance of the pin the worker counts as there.
  static const arrivedWithin = 60.0;

  /// A new road route is asked for after the worker moves this far from
  /// where the last one started, or after [routeMaxAge].
  static const rerouteAfterMetres = 150.0;
  static const routeMaxAge = Duration(minutes: 2);

  @override
  ConsumerState<ContractTrackingScreen> createState() => _ContractTrackingScreenState();
}

class _ContractTrackingScreenState extends ConsumerState<ContractTrackingScreen> {
  Timer? _tick;
  SbMapController? _map;

  /// Keep the worker and the pin in view until the person moves the map.
  bool _follow = true;

  RouteSummary? _route;
  GeoCoord? _routeFrom;
  DateTime? _routeAt;
  bool _routing = false;
  bool _routeFailed = false;

  /// Asks for the road route from the worker when there is none yet, they
  /// moved far from where it started, or it is old. Never for a stale
  /// position, and not again soon after a failure.
  Future<void> _maybeRoute(LiveLocation? loc, GeoCoord? pin) async {
    if (_routing || loc == null || pin == null || !_isLive(loc)) return;
    final api = ref.read(mapsApiProvider);
    if (!api.available) return;
    final from = GeoCoord(loc.lat, loc.lng);
    final old = _routeAt == null || DateTime.now().difference(_routeAt!) > ContractTrackingScreen.routeMaxAge;
    final moved = _routeFrom == null ? double.infinity : distanceMetres(_routeFrom!, from);
    if (_route != null && moved < ContractTrackingScreen.rerouteAfterMetres && !old) return;
    if (_route == null && _routeFailed && !old) return;
    _routing = true;
    try {
      final r = await api.route(from, pin);
      if (!mounted) return;
      setState(() {
        _route = r;
        _routeFrom = from;
        _routeAt = DateTime.now();
        _routeFailed = false;
      });
    } on MapsApiException {
      if (!mounted) return;
      setState(() {
        _routeFailed = true;
        _routeAt = DateTime.now();
      });
    } finally {
      _routing = false;
    }
  }

  void _frame(LiveLocation? loc, GeoCoord? pin) {
    final pts = [if (loc != null) GeoCoord(loc.lat, loc.lng), ?pin];
    if (pts.isNotEmpty) _map?.fit(pts, padding: 72, maxZoom: 16);
  }

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
    super.dispose();
  }

  bool _isLive(LiveLocation? loc) => loc != null && loc.isLive(DateTime.now()) && (ref.read(connectivityStatusProvider).value ?? true);

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

    ref.listen<AsyncValue<LiveLocation?>>(contractLiveLocationProvider(c.id), (previous, next) {
      if (_follow) _frame(next.value, c.serviceLocation);
      _maybeRoute(next.value, c.serviceLocation);
    });
    final liveAsync = ref.watch(contractLiveLocationProvider(c.id));
    final loc = liveAsync.value;
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final live = _isLive(loc);
    final pin = c.serviceLocation;
    final here = loc == null ? null : GeoCoord(loc.lat, loc.lng);
    final atPlace = live && here != null && pin != null && distanceMetres(here, pin) <= ContractTrackingScreen.arrivedWithin;
    if (_route == null && !_routing && !_routeFailed && live) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeRoute(loc, pin);
      });
    }
    final route = live && !atPlace ? _route : null;

    return Scaffold(
      appBar: AppBar(title: Text(l.trackTitle)),
      body: Column(children: [
        Expanded(
          child: SbGoogleMap(
            initialCenter: here ?? pin ?? const GeoCoord(30.3753, 69.3451),
            initialZoom: here != null || pin != null ? 14 : 5,
            onCreated: (m) {
              _map = m;
              _frame(loc, pin);
            },
            onUserGesture: () {
              if (_follow) setState(() => _follow = false);
            },
            onRecenter: here == null && pin == null
                ? null
                : () {
                    setState(() => _follow = true);
                    _frame(loc, pin);
                  },
            showZoomButtons: true,
            polylines: [if (route != null) SbPolyline(id: 'route', points: route.points)],
            circles: [
              if (here != null && (loc!.accuracy ?? 0) > 0 && (loc.accuracy ?? 0) < 2000)
                SbCircle(id: 'accuracy', center: here, radiusMetres: loc.accuracy!),
            ],
            markers: [
              if (pin != null) SbMarker(id: 'pin', position: pin, kind: SbMarkerKind.destination, title: l.contractPinTitle),
              if (here != null) SbMarker(id: 'worker', position: here, kind: SbMarkerKind.person, title: c.workerName, stale: !live),
            ],
          ),
        ),
        _TrackingPanel(
          contract: c,
          location: loc,
          loading: loc == null && liveAsync.isLoading,
          failed: loc == null && liveAsync.hasError,
          onRetry: () => ref.invalidate(contractLiveLocationProvider(c.id)),
          live: live,
          online: online,
          atPlace: atPlace,
          route: route,
          routeFailed: live && _routeFailed && _route == null && ref.read(mapsApiProvider).available,
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
    required this.atPlace,
    required this.route,
    required this.routeFailed,
  });

  final ContractEntity contract;
  final LiveLocation? location;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final bool live;
  final bool online;
  final bool atPlace;
  final RouteSummary? route;
  final bool routeFailed;

  String _clock(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ur' ? DateFormat.Hm('ur').format(at) : DateFormat.jm(locale.toLanguageTag()).format(at);
  }

  String _ago(BuildContext context, DateTime at) {
    final l = context.l10n;
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 45) return l.liveJustNow;
    if (d.inMinutes < 60) return l.liveMinutesAgo(d.inMinutes.clamp(1, 59));
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
      children.add(Align(
        alignment: AlignmentDirectional.centerStart,
        child: SbButton(
          label: l.liveOpenInMaps,
          icon: Icons.open_in_new_rounded,
          variant: SbButtonVariant.quiet,
          size: SbButtonSize.compact,
          onPressed: () => GoogleMapsLinks.open(GoogleMapsLinks.place(GeoCoord(loc.lat, loc.lng))),
        ),
      ));
      if (!live) {
        children.add(online
            ? SbInlineBanner(message: l.liveClientStale(c.workerName), tone: SbTone.warning)
            : SbOfflineNote(message: l.liveClientOffline));
      } else if (atPlace) {
        children.add(SbInlineBanner(message: l.trackArrived(c.workerName), tone: SbTone.success));
      } else if (c.serviceLocation == null) {
        children.add(Text(l.trackNoPin, style: t.bodyMedium));
      } else if (route != null) {
        final r = route!;
        children.add(Text(
          l.trackRoadLeft(formatRouteDistance(l, r.distanceMeters), formatRouteDuration(l, r.durationSeconds)),
          style: SbTypography.numeric(t.titleMedium!).copyWith(color: sb.success, fontWeight: FontWeight.w700),
        ));
        children.add(Text(l.trackArriveAbout(_clock(context, DateTime.now().add(Duration(seconds: r.durationSeconds)))), style: t.bodyMedium));
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
