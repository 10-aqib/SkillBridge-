import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/map/map_markers.dart';
import 'package:skill_bridge/core/map/sb_map.dart';
import 'package:skill_bridge/core/services/location_tracking_service.dart';
import 'package:skill_bridge/features/contracts/data/models/live_location.dart';
import 'package:skill_bridge/features/contracts/domain/entities/contract_entity.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether location sharing applies to a contract right now: hired and the
/// work not yet submitted (the same window the rules accept positions in).
bool liveLocationOpen(ContractEntity c) => c.stage == ContractStage.notStarted || c.stage == ContractStage.inProgress;

String _ago(BuildContext context, DateTime at, DateTime now) {
  final l = context.l10n;
  final d = now.difference(at);
  if (d.inSeconds < 45) return l.liveJustNow;
  if (d.inMinutes < 60) return l.liveMinutesAgo(d.inMinutes.clamp(1, 59));
  return DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(at);
}

/// The hired worker's control: explicit consent, start/stop, and every
/// state the device can be in (permission, GPS off, offline, ended).
class WorkerLocationSharingPanel extends ConsumerStatefulWidget {
  const WorkerLocationSharingPanel({super.key, required this.contract});
  final ContractEntity contract;

  @override
  ConsumerState<WorkerLocationSharingPanel> createState() => _WorkerLocationSharingPanelState();
}

class _WorkerLocationSharingPanelState extends ConsumerState<WorkerLocationSharingPanel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  ContractEntity get c => widget.contract;

  Future<void> _start() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: l.liveConsentTitle,
      message: l.liveConsentBody(c.clientName),
      confirmLabel: l.liveConsentAgree,
      cancelLabel: l.liveNotNow,
    );
    if (!ok || !mounted) return;
    final status = await ref.read(liveLocationControllerProvider.notifier).start(c.id);
    if (!mounted) return;
    if (status == LiveShareStatus.sharing) context.showSnackBar(l.liveStartedNotice(c.clientName));
  }

  Future<void> _stop() async {
    await ref.read(liveLocationControllerProvider.notifier).stop();
    if (mounted) context.showSnackBar(context.l10n.liveStoppedNotice);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final state = ref.watch(liveLocationControllerProvider);
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final controller = ref.read(liveLocationControllerProvider.notifier);
    final mine = state.contractId == c.id;
    final sharing = mine && state.status == LiveShareStatus.sharing;
    final starting = mine && state.status == LiveShareStatus.starting;
    final now = DateTime.now();

    final (String? problem, String? fixLabel, VoidCallback? fix) = !mine
        ? (null, null, null)
        : switch (state.status) {
            LiveShareStatus.permissionDenied => (l.livePermissionDenied, l.tryAgain, _start),
            LiveShareStatus.permissionBlocked => (l.livePermissionBlocked, l.liveOpenSettings, () => controller.source.openAppSettings()),
            LiveShareStatus.serviceOff => (l.liveServiceOff, l.liveOpenSettings, () => controller.source.openLocationSettings()),
            LiveShareStatus.unavailable => (l.liveUnavailable, null, null),
            LiveShareStatus.ended => (l.liveEnded, null, null),
            LiveShareStatus.error => (l.liveError, l.tryAgain, _start),
            _ => (null, null, null),
          };

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(sharing ? Icons.location_on_rounded : Icons.location_off_outlined, color: sharing ? context.sb.success : context.sb.textSecondary),
        const SizedBox(width: SbSpace.s2),
        Expanded(
          child: Text(
            sharing
                ? l.liveSharingWith(c.clientName, state.lastSentAt == null ? l.liveJustNow : _ago(context, state.lastSentAt!, now))
                : starting
                    ? l.liveStarting
                    : l.liveWorkerIntro(c.clientName),
            style: t.bodyMedium,
          ),
        ),
      ]),
      if (sharing && !online) ...[
        const SizedBox(height: SbSpace.s3),
        SbInlineBanner(message: l.liveOfflineWorker, tone: SbTone.warning),
      ],
      if (problem != null) ...[
        const SizedBox(height: SbSpace.s3),
        SbInlineBanner(
          message: problem,
          tone: state.status == LiveShareStatus.ended ? SbTone.neutral : SbTone.warning,
          actionLabel: fixLabel,
          onAction: fix,
        ),
      ],
      const SizedBox(height: SbSpace.s3),
      if (sharing)
        SbButton(label: l.liveStopSharing, icon: Icons.location_disabled_outlined, variant: SbButtonVariant.secondary, expand: true, onPressed: _stop)
      else
        SbButton(
          label: l.liveStartSharing,
          icon: Icons.share_location_rounded,
          variant: SbButtonVariant.secondary,
          expand: true,
          isLoading: starting,
          onPressed: starting ? null : _start,
        ),
    ]);
  }
}

/// The client's view: live position (updated under two minutes ago), last
/// known position marked as possibly out of date, or "not sharing".
class ClientLiveLocationPanel extends ConsumerStatefulWidget {
  const ClientLiveLocationPanel({super.key, required this.contract});
  final ContractEntity contract;

  @override
  ConsumerState<ClientLiveLocationPanel> createState() => _ClientLiveLocationPanelState();
}

class _ClientLiveLocationPanelState extends ConsumerState<ClientLiveLocationPanel> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Re-check freshness so a position turns "not live" on time.
    _tick = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final c = widget.contract;
    final async = ref.watch(contractLiveLocationProvider(c.id));
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final now = DateTime.now();

    final loc = async.value;
    final Widget body;
    if (loc == null && async.isLoading) {
      body = const Padding(padding: EdgeInsets.all(SbSpace.s4), child: Center(child: CircularProgressIndicator()));
    } else if (loc == null && async.hasError) {
      body = SbInlineBanner(
        message: l.liveLoadError,
        tone: SbTone.error,
        actionLabel: l.tryAgain,
        onAction: () => ref.invalidate(contractLiveLocationProvider(c.id)),
      );
    } else if (loc == null) {
      body = Row(children: [
        Icon(Icons.location_off_outlined, color: sb.textSecondary),
        const SizedBox(width: SbSpace.s2),
        Expanded(child: Text(l.liveClientNotSharing(c.workerName), style: t.bodyMedium)),
      ]);
    } else {
      final live = loc.isLive(now) && online;
      final updated = loc.updatedAt ?? now;
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (live)
            SbStatusBadge(label: l.liveBadge, icon: Icons.circle, tone: SbTone.success)
          else
            SbStatusBadge(label: l.liveBadgeStale, icon: Icons.history_rounded, tone: SbTone.warning),
          const SizedBox(width: SbSpace.s2),
          Expanded(child: Text(l.liveUpdated(_ago(context, updated, now)), style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        if (!live) ...[
          const SizedBox(height: SbSpace.s2),
          SbInlineBanner(message: online ? l.liveClientStale(c.workerName) : l.liveClientOffline, tone: SbTone.warning),
        ],
        const SizedBox(height: SbSpace.s3),
        LiveLocationMap(location: loc, live: live, label: c.workerName),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      body,
      const SizedBox(height: SbSpace.s2),
      Text(l.liveClientExplainer(c.workerName), style: t.bodySmall),
    ]);
  }
}

/// The worker's position on a small OpenStreetMap preview (no gestures, so
/// the page scrolls normally) that follows each update, plus a link to open
/// it in the device's maps app. Out-of-date positions are drawn dimmed.
class LiveLocationMap extends StatefulWidget {
  const LiveLocationMap({super.key, required this.location, required this.live, required this.label});
  final LiveLocation location;
  final bool live;
  final String label;

  /// Opens the position in whatever maps app the device has: a `geo:` link
  /// on Android, Apple Maps on iOS and macOS, OpenStreetMap elsewhere.
  static Uri mapsLink(double lat, double lng, {TargetPlatform? platform, bool web = kIsWeb}) {
    final ll = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    if (!web) {
      switch (platform ?? defaultTargetPlatform) {
        case TargetPlatform.android:
          return Uri.parse('geo:$ll?q=$ll');
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          return Uri.https('maps.apple.com', '/', {'q': ll, 'll': ll});
        default:
          break;
      }
    }
    return webMapsLink(lat, lng);
  }

  static Uri webMapsLink(double lat, double lng) => Uri.parse(
      'https://www.openstreetmap.org/?mlat=${lat.toStringAsFixed(6)}&mlon=${lng.toStringAsFixed(6)}#map=17/${lat.toStringAsFixed(6)}/${lng.toStringAsFixed(6)}');

  @override
  State<LiveLocationMap> createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
  final _map = MapController();
  bool _ready = false;

  LatLng get _point => LatLng(widget.location.lat, widget.location.lng);

  @override
  void didUpdateWidget(LiveLocationMap old) {
    super.didUpdateWidget(old);
    if (_ready && (old.location.lat != widget.location.lat || old.location.lng != widget.location.lng)) {
      _map.move(_point, _map.camera.zoom);
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final loc = widget.location;
    try {
      if (await launchUrl(LiveLocationMap.mapsLink(loc.lat, loc.lng), mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    // No app handles geo: links: the web map always works.
    await launchUrl(LiveLocationMap.webMapsLink(loc.lat, loc.lng), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final location = widget.location;
    final accuracy = location.accuracy;
    final point = _point;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(SbRadius.card),
        child: SizedBox(
          height: 200,
          child: SbMap(
            controller: _map,
            initialCenter: point,
            initialZoom: 15,
            interactive: false,
            semanticLabel: '${l.mapLabel}: ${widget.label}',
            onMapReady: () => _ready = true,
            layers: [
              if (accuracy != null && accuracy > 0 && accuracy < 2000)
                CircleLayer(circles: [sbAccuracyCircle(context, point, accuracy)]),
              MarkerLayer(markers: [sbPersonMarker(point, name: widget.label, stale: !widget.live)]),
            ],
          ),
        ),
      ),
      const SizedBox(height: SbSpace.s2),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${location.lat.toStringAsFixed(5)}, ${location.lng.toStringAsFixed(5)}',
                style: SbTypography.numeric(t.bodyMedium!), textDirection: TextDirection.ltr),
            if (accuracy != null) Text(l.liveAccuracy(accuracy.round()), style: t.bodySmall),
          ]),
        ),
        SbButton(
          label: l.liveOpenInMaps,
          icon: Icons.open_in_new_rounded,
          variant: SbButtonVariant.quiet,
          size: SbButtonSize.compact,
          onPressed: _open,
        ),
      ]),
    ]);
  }
}
