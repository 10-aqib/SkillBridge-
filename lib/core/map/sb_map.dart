import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/map/map_config.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';

/// The one map widget every screen uses (Navigation phase 3): OpenStreetMap
/// compatible raster tiles from [MapTileConfig], the attribution the tile
/// licence requires, and the states a map can be in: unavailable (bad
/// configuration), offline, and tiles failing to load.
///
/// Screens add their own layers ([layers]: polylines, circles, markers) and
/// keep a [MapController] when they need to move the camera.

/// Makes the tile provider for one tile layer. [TileLayer] disposes the
/// provider it is given, so every layer gets a fresh one. Tests override
/// this with tiles that need no network.
final mapTileProviderFactory = Provider<TileProvider Function()>((ref) {
  // Built-in caching (non-web) follows the tiles' HTTP cache headers, as the
  // OpenStreetMap tile policy asks; nothing is downloaded ahead.
  return () => NetworkTileProvider();
});

/// Tile errors before the map says it couldn't load, when nothing loaded.
const _tileErrorsBeforeNotice = 4;

class SbMap extends ConsumerStatefulWidget {
  const SbMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15,
    this.controller,
    this.layers = const [],
    this.interactive = true,
    this.allowRotation = true,
    this.onTap,
    this.onPositionChanged,
    this.onMapReady,
    this.onRecenter,
    this.showZoomButtons = false,
    this.minZoom = 3,
    this.semanticLabel,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final MapController? controller;

  /// Map layers above the tiles (PolylineLayer, CircleLayer, MarkerLayer).
  final List<Widget> layers;

  /// False for small previews inside scrolling pages: no gestures, so the
  /// page scrolls normally.
  final bool interactive;
  final bool allowRotation;
  final void Function(TapPosition, LatLng)? onTap;
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;
  final VoidCallback? onMapReady;

  /// Shows a "my location" button that calls this.
  final VoidCallback? onRecenter;
  final bool showZoomButtons;
  final double minZoom;

  /// Read by screen readers for the whole map.
  final String? semanticLabel;

  @override
  ConsumerState<SbMap> createState() => _SbMapState();
}

class _SbMapState extends ConsumerState<SbMap> {
  MapController? _ownController;
  MapController get _controller => widget.controller ?? (_ownController ??= MapController());

  int _tileGeneration = 0;
  int _tileErrors = 0;
  bool _anyTileLoaded = false;

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  void _onTileError(TileImage tile, Object error, StackTrace? stack) {
    if (!mounted || _anyTileLoaded) return;
    _tileErrors++;
    if (_tileErrors == _tileErrorsBeforeNotice) setState(() {});
  }

  void _retryTiles() {
    setState(() {
      _tileErrors = 0;
      _anyTileLoaded = false;
      _tileGeneration++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(mapTileConfigProvider);
    final l = context.l10n;
    if (!config.isValid) {
      return SbMapUnavailable(title: l.mapUnavailableTitle, message: l.mapUnavailableBody);
    }
    final makeTiles = ref.watch(mapTileProviderFactory);
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final failing = online && !_anyTileLoaded && _tileErrors >= _tileErrorsBeforeNotice;

    final flags = !widget.interactive
        ? InteractiveFlag.none
        : widget.allowRotation
            ? InteractiveFlag.all
            : InteractiveFlag.all & ~InteractiveFlag.rotate;

    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: widget.minZoom,
        maxZoom: config.maxZoom.toDouble(),
        backgroundColor: context.sb.surfaceSunken,
        interactionOptions: InteractionOptions(flags: flags),
        onTap: widget.onTap,
        onPositionChanged: widget.onPositionChanged,
        onMapReady: widget.onMapReady,
      ),
      children: [
        TileLayer(
          key: ValueKey('tiles-$_tileGeneration'),
          urlTemplate: config.urlTemplate,
          subdomains: config.subdomains,
          maxNativeZoom: config.maxZoom,
          userAgentPackageName: appUserAgentPackage,
          tileProvider: makeTiles(),
          errorTileCallback: _onTileError,
          // OSM has no dark tiles; an inverted, hue-rotated filter keeps the
          // map readable in the dark theme.
          tileBuilder: (context, tile, image) {
            if (!_anyTileLoaded && image.loadFinishedAt != null && !image.loadError) {
              _anyTileLoaded = true;
              // Clear a "couldn't load" notice once tiles do arrive.
              if (_tileErrors >= _tileErrorsBeforeNotice) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              }
            }
            return dark ? darkModeTileBuilder(context, tile, image) : tile;
          },
        ),
        ...widget.layers,
        if (widget.interactive)
          _MapControls(
            onRecenter: widget.onRecenter,
            showZoom: widget.showZoomButtons,
            allowRotation: widget.allowRotation,
          ),
        _Attribution(config: config),
      ],
    );

    return Semantics(
      label: widget.semanticLabel ?? l.mapLabel,
      container: true,
      child: Stack(children: [
        Positioned.fill(child: map),
        if (!online || failing)
          PositionedDirectional(
            top: SbSpace.s2,
            start: SbSpace.s2,
            end: SbSpace.s2,
            child: SbInlineBanner(
              message: online ? l.mapTilesFailed : l.mapOffline,
              tone: SbTone.warning,
              actionLabel: online ? l.tryAgain : null,
              onAction: online ? _retryTiles : null,
            ),
          ),
      ]),
    );
  }
}

/// Recenter, zoom and compass buttons, on the trailing edge.
class _MapControls extends StatelessWidget {
  const _MapControls({required this.onRecenter, required this.showZoom, required this.allowRotation});
  final VoidCallback? onRecenter;
  final bool showZoom;
  final bool allowRotation;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final camera = MapCamera.of(context);
    final controller = MapController.of(context);
    final rotated = allowRotation && camera.rotation.abs() % 360 > 0.5;
    return PositionedDirectional(
      end: SbSpace.s3,
      bottom: SbSpace.s8,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (rotated)
          _MapButton(
            tooltip: l.mapResetNorth,
            onPressed: () => controller.rotate(0),
            child: Transform.rotate(
              angle: -camera.rotationRad,
              child: const Icon(Icons.navigation_rounded),
            ),
          ),
        if (showZoom) ...[
          _MapButton(
            tooltip: l.mapZoomIn,
            onPressed: () => controller.move(camera.center, (camera.zoom + 1).clamp(camera.minZoom ?? 0, camera.maxZoom ?? 22)),
            child: const Icon(Icons.add_rounded),
          ),
          _MapButton(
            tooltip: l.mapZoomOut,
            onPressed: () => controller.move(camera.center, (camera.zoom - 1).clamp(camera.minZoom ?? 0, camera.maxZoom ?? 22)),
            child: const Icon(Icons.remove_rounded),
          ),
        ],
        if (onRecenter != null)
          _MapButton(tooltip: l.mapRecenter, onPressed: onRecenter!, child: const Icon(Icons.my_location_rounded)),
      ]),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.tooltip, required this.onPressed, required this.child});
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    return Padding(
      padding: const EdgeInsets.only(top: SbSpace.s2),
      child: Material(
        color: sb.surfaceRaised,
        shape: CircleBorder(side: BorderSide(color: sb.border)),
        elevation: 2,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          color: sb.primary,
          constraints: const BoxConstraints.tightFor(width: SbTarget.mobile, height: SbTarget.mobile),
          icon: child,
        ),
      ),
    );
  }
}

/// The tile provider's credit, always visible (the OSM licence and tile
/// policy require it; it must not be hidden behind a toggle).
class _Attribution extends StatelessWidget {
  const _Attribution({required this.config});
  final MapTileConfig config;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Semantics(
        link: true,
        label: '${context.l10n.mapAttributionLabel}: ${config.attribution}',
        excludeSemantics: true,
        child: Material(
          color: sb.surface.withValues(alpha: 0.85),
          borderRadius: const BorderRadiusDirectional.only(topStart: Radius.circular(SbRadius.xs)),
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(config.attributionUrl), mode: LaunchMode.externalApplication),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SbSpace.s2, vertical: 2),
              // Credits are left-to-right text, also in Urdu.
              child: Text(config.attribution, textDirection: TextDirection.ltr, style: t.labelSmall?.copyWith(color: sb.text)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of a map when it can't be drawn at all.
class SbMapUnavailable extends StatelessWidget {
  const SbMapUnavailable({super.key, required this.title, this.message, this.action});
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final sb = context.sb;
    final t = Theme.of(context).textTheme;
    return Container(
      color: sb.surfaceSunken,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(SbSpace.s4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.map_outlined, size: 32, color: sb.textSecondary),
        const SizedBox(height: SbSpace.s2),
        Text(title, style: t.titleSmall, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: SbSpace.s1),
          Text(message!, style: t.bodySmall, textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: SbSpace.s3), action!],
      ]),
    );
  }
}

/// Camera helpers shared by screens.
extension SbMapCamera on MapController {
  /// Frames all [points] (at least one) with [padding] around them, never
  /// zooming past [maxZoom] (so two close points don't fill the screen).
  void frame(List<LatLng> points, {EdgeInsets padding = const EdgeInsets.all(48), double maxZoom = 17}) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      move(points.first, maxZoom.clamp(3, 17));
      return;
    }
    fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: padding, maxZoom: maxZoom));
  }
}
