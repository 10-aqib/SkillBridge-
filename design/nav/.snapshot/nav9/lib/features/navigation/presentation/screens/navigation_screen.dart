import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/location/device_location.dart';
import 'package:skill_bridge/core/map/map_markers.dart';
import 'package:skill_bridge/core/map/sb_map.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/navigation_controller.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/voice_guidance.dart';
import 'package:skill_bridge/features/navigation/presentation/widgets/nav_panels.dart';
import 'package:skill_bridge/features/navigation/presentation/widgets/route_layer.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Turn-by-turn navigation to [destination] (Navigation phase 6): the route
/// on a full-screen map that follows the user (course up when the heading
/// is reliable), the next maneuver on top, time/distance/arrival and End at
/// the bottom. Guidance runs while the screen is open and the app is in the
/// foreground; the screen stays on meanwhile.
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.destination, this.label});

  /// Where to go; null shows "no map location yet" (never a guessed place).
  final LatLng? destination;
  final String? label;

  /// Zoom while following the user.
  static const followZoom = 17.0;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final _map = MapController();
  bool _mapReady = false;
  bool _follow = true;
  Size _mapSize = Size.zero;

  /// Last reliable heading, so the arrow doesn't snap north when stopped.
  double? _lastHeading;
  late final AppLifecycleListener _lifecycle;

  NavigationController get _controller => ref.read(navigationControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Coming back from Settings (permission, GPS) tries again by itself.
    _lifecycle = AppLifecycleListener(onResume: () {
      final s = ref.read(navigationControllerProvider);
      const fixable = {NavError.permissionDenied, NavError.permissionBlocked, NavError.serviceOff, NavError.noFix, NavError.offline};
      if (s.status == NavStatus.error && fixable.contains(s.error)) _controller.retry();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.prepare(widget.destination, label: widget.label);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Directions are spoken in the screen's language.
    ref.read(navigationVoiceProvider.notifier).setLanguage(Localizations.localeOf(context).languageCode);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onState(NavState? previous, NavState next) {
    if (!_mapReady) return;
    if (next.status == NavStatus.ready && previous?.status != NavStatus.ready) {
      // Show the whole trip and its options before starting.
      final routes = next.result?.all ?? const [];
      _map.frame([
        if (next.fix != null) next.fix!.point,
        if (next.destination != null) next.destination!,
        for (final r in routes) ...r.points,
      ], padding: const EdgeInsets.fromLTRB(48, 96, 48, 320));
    }
    if (next.status == NavStatus.navigating && previous?.status == NavStatus.ready) _follow = true;
    if (next.status == NavStatus.navigating && _follow && next.fix != null) _followUser(next);
  }

  /// Keeps the user low on the screen with the road ahead visible, and turns
  /// the map to their direction of travel when that is reliable.
  void _followUser(NavState s) {
    final fix = s.fix!;
    final progress = s.progress;
    if (fix.hasReliableHeading) _lastHeading = fix.heading;
    final point = progress != null && progress.distanceFromRoute < 25 ? progress.snap.point : fix.point;
    if (fix.hasReliableHeading) _map.rotate(-fix.heading!);
    _map.move(point, NavigationScreen.followZoom, offset: Offset(0, _mapSize.height * 0.22));
  }

  void _recenter() {
    final s = ref.read(navigationControllerProvider);
    final fix = s.fix;
    if (fix == null) return;
    setState(() => _follow = true);
    if (s.isGuiding) {
      _followUser(s);
    } else {
      _map.move(fix.point, 16);
    }
  }

  Future<void> _confirmEnd() async {
    final l = context.l10n;
    final ok = await showSbConfirmSheet(
      context,
      title: l.navEndTitle,
      message: l.navEndBody,
      confirmLabel: l.navEnd,
      cancelLabel: l.navKeepGoing,
    );
    if (!ok || !mounted) return;
    _close();
  }

  /// Ends the session and leaves. `pop`, not `maybePop`: the back-guard
  /// below still holds the guiding state until the next frame.
  void _close() {
    _controller.end();
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(navigationControllerProvider);
    ref.listen<NavState>(navigationControllerProvider, _onState);
    // Keeps voice guidance alive for this screen; tells once if the voice
    // had to fall back to English or isn't available.
    ref.watch(navigationVoiceProvider);
    ref.listen<VoiceState>(navigationVoiceProvider, (previous, next) {
      if (next.notice != (previous?.notice ?? VoiceNotice.none)) {
        if (next.notice == VoiceNotice.englishFallback) context.showSnackBar(l.navVoiceEnglishFallback);
        if (next.notice == VoiceNotice.unavailable) context.showSnackBar(l.navVoiceUnavailable);
      }
    });
    final muted = ref.watch(voiceMutedProvider);
    final place = (widget.label ?? '').trim().isNotEmpty ? widget.label!.trim() : l.navYourDestination;
    final route = s.route;
    final fix = s.fix;
    final progress = s.progress;
    final onRoute = progress != null && progress.distanceFromRoute < 25;
    final source = ref.read(locationSourceProvider);

    Widget bottom;
    switch (s.status) {
      case NavStatus.initializing:
      case NavStatus.locating:
        bottom = NavBusyPanel(message: l.pickerLocating, onCancel: _close);
      case NavStatus.calculating:
        bottom = NavBusyPanel(message: l.navCalculating, onCancel: _close);
      case NavStatus.rerouting:
        // Keeps End reachable; the figures update with the new route.
        bottom = progress == null ? NavBusyPanel(message: l.navCalculating) : NavTripPanel(progress: progress, onEnd: _confirmEnd);
      case NavStatus.ready:
        bottom = NavRouteChooser(
          routes: s.result!.all,
          selected: s.selected,
          place: place,
          onSelect: _controller.selectRoute,
          onStart: _controller.start,
        );
      case NavStatus.navigating:
      case NavStatus.paused:
        bottom = progress == null
            ? NavBusyPanel(message: l.navResuming)
            : NavTripPanel(progress: progress, onEnd: _confirmEnd);
      case NavStatus.arrived:
        bottom = NavArrivedPanel(place: place, onDone: _close);
      case NavStatus.cancelled:
        bottom = const SizedBox.shrink();
      case NavStatus.error:
        final (message, action, onAction) = switch (s.error) {
          NavError.noDestination => (l.navErrNoDestination, null, null),
          NavError.permissionDenied => (l.navErrPermission, l.tryAgain, _controller.retry),
          NavError.permissionBlocked => source.canOpenSettings
              ? (l.navErrBlocked, l.liveOpenSettings, source.openAppSettings)
              : (l.navErrBlocked, l.tryAgain, _controller.retry),
          NavError.serviceOff => source.canOpenSettings
              ? (l.navErrServiceOff, l.liveOpenSettings, source.openLocationSettings)
              : (l.navErrServiceOff, l.tryAgain, _controller.retry),
          NavError.noFix => (l.navErrNoFix, l.tryAgain, _controller.retry),
          NavError.noRoute => (l.navErrNoRoute, l.tryAgain, _controller.retry),
          NavError.farFromRoad => (l.navErrFarFromRoad, null, null),
          NavError.offline => (l.navErrOffline, l.tryAgain, _controller.retry),
          NavError.routing || null => (l.navErrRouting, l.tryAgain, _controller.retry),
        };
        bottom = NavProblemPanel(message: message, actionLabel: action, onAction: onAction, onClose: _close);
    }

    final banners = <Widget>[
      if (s.status == NavStatus.navigating && s.rerouteProblem != null)
        switch (s.rerouteProblem!) {
          NavError.offline => SbInlineBanner(message: l.navRerouteOffline, tone: SbTone.warning),
          NavError.noRoute => SbInlineBanner(message: l.navRerouteNoRoute, tone: SbTone.warning),
          _ => SbInlineBanner(message: l.navRerouteFailed, tone: SbTone.warning, actionLabel: l.tryAgain, onAction: _controller.rerouteNow),
        },
      if (s.status == NavStatus.paused) SbInlineBanner(message: l.navResuming, tone: SbTone.info),
      if (s.isGuiding && s.signalLost && s.status != NavStatus.paused) SbInlineBanner(message: l.navSignalLost, tone: SbTone.warning),
      if (s.isGuiding && !s.precise) SbInlineBanner(message: l.navApproximate, tone: SbTone.warning),
    ];

    return PopScope(
      canPop: !s.isGuiding,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && s.isGuiding) _confirmEnd();
      },
      child: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              _mapSize = constraints.biggest;
              return SbMap(
                controller: _map,
                initialCenter: widget.destination ?? const LatLng(30.3753, 69.3451),
                initialZoom: widget.destination != null ? 14 : 5,
                semanticLabel: l.navTitle,
                onRecenter: fix == null ? null : _recenter,
                onMapReady: () {
                  _mapReady = true;
                  _onState(null, ref.read(navigationControllerProvider));
                },
                onPositionChanged: (camera, hasGesture) {
                  // Moving the map by hand stops following until Recenter.
                  if (hasGesture && _follow && s.isGuiding) setState(() => _follow = false);
                },
                layers: [
                  if (route != null) SbRouteLayer(route: route, alternatives: s.status == NavStatus.ready ? s.otherRoutes : const []),
                  MarkerLayer(markers: [
                    if (widget.destination != null) sbDestinationMarker(widget.destination!, semanticLabel: place),
                    if (fix != null)
                      sbCurrentLocationMarker(
                        s.isGuiding && onRoute ? progress.snap.point : fix.point,
                        heading: fix.hasReliableHeading ? fix.heading : (s.isGuiding ? _lastHeading : null),
                        dimmed: s.signalLost,
                        arrow: s.isGuiding,
                        semanticLabel: l.mapYouAreHere,
                      ),
                  ]),
                ],
              );
            }),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(SbSpace.s3),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (s.status == NavStatus.rerouting)
                    const NavReroutingCard()
                  else if (s.isGuiding && progress != null)
                    NavInstructionCard(progress: progress)
                  else if (s.status != NavStatus.arrived)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Material(
                        color: context.sb.surfaceRaised,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: IconButton(tooltip: l.close, icon: const Icon(Icons.close_rounded), onPressed: _close),
                      ),
                    ),
                  for (final b in banners) Padding(padding: const EdgeInsets.only(top: SbSpace.s2), child: b),
                  if (s.isGuiding)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsets.only(top: SbSpace.s2),
                        child: Material(
                          color: context.sb.surfaceRaised,
                          shape: CircleBorder(side: BorderSide(color: context.sb.border)),
                          elevation: 3,
                          child: IconButton(
                            tooltip: muted ? l.navUnmute : l.navMute,
                            isSelected: muted,
                            icon: Icon(muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: context.sb.primary),
                            onPressed: () => ref.read(voiceMutedProvider.notifier).toggle(),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: bottom),
        ]),
      ),
    );
  }
}
