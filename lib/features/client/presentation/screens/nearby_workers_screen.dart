import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_shadows.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'package:skill_bridge/core/utils/formatters.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/features/client/domain/entities/nearby_worker_entity.dart';
import 'package:skill_bridge/features/client/domain/services/worker_match_service.dart';
import 'package:skill_bridge/core/providers/location_provider.dart';
import 'package:skill_bridge/features/client/presentation/providers/nearby_workers_provider.dart';
import 'package:skill_bridge/shared/widgets/app_avatar.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/booking_payment_sheet.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:go_router/go_router.dart';

/// Skill Bridge Nearby Workers — Real Google Maps with worker pins
class NearbyWorkersScreen extends ConsumerStatefulWidget {
  const NearbyWorkersScreen({super.key});

  @override
  ConsumerState<NearbyWorkersScreen> createState() =>
      _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends ConsumerState<NearbyWorkersScreen>
    with TickerProviderStateMixin {
  String _selectedCity = 'Lahore';
  String _selectedCategory = 'All';
  double _maxDistanceRadiusKm = 5.0;
  double _maxHourlyRate = 3000.0;
  double _minRating = 0.0;
  bool _availableOnly = false;
  bool _isMapView = false;
  String? _selectedWorkerId;
  GoogleMapController? _mapController;
  late AnimationController _filterAnim;
  bool _showFilters = true;

  static const _mapStyle = '''[
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"simplified"}]},
    {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _filterAnim = AnimationController(vsync: this, duration: 300.ms);
    _filterAnim.forward();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _filterAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locAsync = ref.watch(locationProvider);
    
    return locAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: Text(
            AppL10n.select(context, en: 'Find Workers Nearby', ur: 'قریبی کاریگر'),
            style: AppTextStyles.heading3.copyWith(color: Colors.white),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Finding your location...'),
            ],
          ),
        ),
      ),
      error: (err, _) => _buildMainScaffold(context, true), // Fallback
      data: (pos) => _buildMainScaffold(
        context, 
        false, 
        userLat: pos.latitude, 
        userLng: pos.longitude,
      ),
    );
  }

  Widget _buildMainScaffold(BuildContext context, bool isFallback, {double? userLat, double? userLng}) {
    final cityMeta = PakistanConstants.cities.firstWhere(
      (c) => c['name'] == _selectedCity,
      orElse: () => PakistanConstants.cities.first,
    );
    final centerLat = isFallback ? (cityMeta['lat'] as num).toDouble() : userLat!;
    final centerLng = isFallback ? (cityMeta['lng'] as num).toDouble() : userLng!;
    
    final currentUserLocation = GeoPointLocation(
      latitude: centerLat,
      longitude: centerLng,
    );

    final nearbyWorkersAsync = ref.watch(nearbyWorkersProvider(currentUserLocation));
    final categories = [
      'All',
      ...PakistanConstants.categories.map((c) => c['name'] as String)
    ];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          AppL10n.select(context, en: 'Find Workers Nearby', ur: 'قریبی کاریگر'),
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMapView ? Icons.list_alt_rounded : Icons.map_rounded,
              color: Colors.white,
            ),
            tooltip: _isMapView ? 'List View' : 'Map View',
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filters ────────────────────────────────────────────────────────
          AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            child: _showFilters
                ? _buildFilters(context, categories)
                : const SizedBox.shrink(),
          ),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: nearbyWorkersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 64, color: AppColors.outlineVariant),
                    const SizedBox(height: 12),
                    Text('Could not load workers',
                        style: AppTextStyles.bodyStrong.copyWith(
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text('Check your internet connection',
                        style: AppTextStyles.labelCaption.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              data: (allWorkers) {
                final filtered = allWorkers
                    .where((w) => w.distanceKm <= _maxDistanceRadiusKm)
                    .where((w) =>
                        _selectedCategory == 'All' ||
                        w.category == _selectedCategory)
                    .where((w) => w.hourlyRate <= _maxHourlyRate)
                    .where((w) => w.rating >= _minRating)
                    .where((w) => !_availableOnly || w.isAvailable)
                    .toList();

                final sorted = WorkerMatchService.sortWorkersByMatch(
                  workers: filtered,
                  targetCategory: _selectedCategory,
                  maxHourlyRate: _maxHourlyRate,
                );

                if (sorted.isEmpty) {
                  return _buildEmptyState(context);
                }

                return _isMapView
                    ? _buildMapView(context, sorted, centerLat, centerLng)
                    : _buildListView(context, sorted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, List<String> categories) {
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: [
          // City + Category row
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'City',
                  value: _selectedCity,
                  items: PakistanConstants.cities.map((c) => c['name'] as String).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: 'Category',
                  value: _selectedCategory,
                  items: categories,
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Distance slider
          Row(
            children: [
              const Icon(Icons.near_me_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Within',
                style: AppTextStyles.labelCaption.copyWith(
                    color: AppColors.onSurface),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  GeoLocationUtil.formatInDriveDistance(_maxDistanceRadiusKm),
                  style: AppTextStyles.labelCaption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _maxDistanceRadiusKm,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.outlineVariant,
              onChanged: (val) => setState(() => _maxDistanceRadiusKm = val),
            ),
          ),
          // Rating + Available row
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [0.0, 4.0, 4.5].map((r) {
                    return ChoiceChip(
                      label: Text(r == 0.0 ? 'All ★' : '★ ${r.toStringAsFixed(1)}+'),
                      selected: _minRating == r,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _minRating == r ? Colors.white : null,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _minRating = r),
                    );
                  }).toList(),
                ),
              ),
              Switch(
                value: _availableOnly,
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : null,
                ),
                onChanged: (v) => setState(() => _availableOnly = v),
              ),
              Text(
                'Available',
                style: AppTextStyles.labelCaption.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        color: context.surfaceColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          style: AppTextStyles.bodyMedium.copyWith(color: context.textColor),
          dropdownColor: context.surfaceColor,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMapView(BuildContext context, List<NearbyWorkerEntity> workers,
      double centerLat, double centerLng) {
    final selectedWorker = workers.firstWhere(
      (w) => w.workerId == _selectedWorkerId,
      orElse: () => workers.first,
    );

    // Build markers
    final Set<Marker> markers = {
      // My location marker
      Marker(
        markerId: const MarkerId('my_location'),
        position: LatLng(centerLat, centerLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '📍 Your Location'),
      ),
      // Worker markers
      ...workers.map((w) => Marker(
            markerId: MarkerId(w.workerId),
            position: LatLng(w.location.latitude, w.location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              w.workerId == _selectedWorkerId
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: w.name,
              snippet:
                  '${w.category} • ${GeoLocationUtil.formatInDriveDistance(w.distanceKm)} away',
            ),
            onTap: () => setState(() => _selectedWorkerId = w.workerId),
          )),
    };

    // 5km radius circle
    final Set<Circle> circles = {
      Circle(
        circleId: const CircleId('search_radius'),
        center: LatLng(centerLat, centerLng),
        radius: _maxDistanceRadiusKm * 1000,
        fillColor: AppColors.primary.withValues(alpha: 0.06),
        strokeColor: AppColors.primary.withValues(alpha: 0.4),
        strokeWidth: 2,
      ),
    };

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 3,
              child: GoogleMap(
                onMapCreated: (ctrl) {
                  _mapController = ctrl;
                },
                style: _mapStyle,
                initialCameraPosition: CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: 13.5,
                ),
                markers: markers,
                circles: circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),
            ),
            // Bottom worker detail card
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                boxShadow: AppShadows.level3,
              ),
              child: Column(
                children: [
                  // Swipeable worker chips
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md, vertical: 8),
                      itemCount: workers.length,
                      itemBuilder: (ctx, i) {
                        final w = workers[i];
                        final isSelected = w.workerId == (
                          _selectedWorkerId ?? workers.first.workerId
                        );
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedWorkerId = w.workerId);
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(w.location.latitude, w.location.longitude),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : context.scaffoldBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                              ),
                            ),
                            child: Text(
                              w.name.split(' ').first,
                              style: TextStyle(
                                color: isSelected ? Colors.white : context.textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Selected worker detail
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: selectedWorker.name,
                          imageUrl: selectedWorker.profilePicture,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.pushNamed(
                                RouteNames.publicWorkerProfileName,
                                pathParameters: {'workerId': selectedWorker.workerId},
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selectedWorker.name,
                                    style: AppTextStyles.heading3.copyWith(
                                        color: context.textColor)),
                                Text(
                                  '${selectedWorker.category} • ★ ${selectedWorker.rating}',
                                  style: AppTextStyles.labelCaption.copyWith(
                                      color: AppColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                _buildDistanceChip(
                                    selectedWorker.distanceKm, context),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'Rs. ${selectedWorker.hourlyRate.toInt()}/hr',
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppButton(
                              text: 'Hire Now',
                              isSmall: true,
                              onPressed: () => BookingPaymentSheet.show(
                                context,
                                workerId: selectedWorker.workerId,
                                workerName: selectedWorker.name,
                                categoryName: selectedWorker.category,
                                hourlyRatePkr: selectedWorker.hourlyRate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // My Location FAB
        Positioned(
          right: 16,
          bottom: 220,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: context.surfaceColor,
            foregroundColor: AppColors.primary,
            child: const Icon(Icons.my_location_rounded),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(LatLng(centerLat, centerLng)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, List<NearbyWorkerEntity> workers) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        final worker = workers[index];
        return _buildWorkerCard(context, worker, index);
      },
    );
  }

  Widget _buildWorkerCard(
      BuildContext context, NearbyWorkerEntity worker, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(AppDimensions.md),
        shadow: AppShadows.level2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match badge
            if (worker.matchScore > 80)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF003FB1), Color(0xFF1A56DB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Top Match — ${worker.matchScore.toInt()}%',
                      style: AppTextStyles.labelCaption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: () {
                context.pushNamed(
                  RouteNames.publicWorkerProfileName,
                  pathParameters: {'workerId': worker.workerId},
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      AppAvatar(
                        name: worker.name,
                        imageUrl: worker.profilePicture,
                        size: 58,
                      ),
                      if (worker.isAvailable)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: context.surfaceColor, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                worker.name,
                                style: AppTextStyles.heading3.copyWith(
                                    color: context.textColor),
                              ),
                            ),
                            const Icon(Icons.verified_rounded,
                                size: 16, color: AppColors.primary),
                          ],
                        ),
                        Text(
                          worker.category,
                          style: AppTextStyles.labelCaption.copyWith(
                              color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildDistanceChip(worker.distanceKm, context),
                            const SizedBox(width: 8),
                            _buildRatingChip(worker.rating, context),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rate',
                        style: AppTextStyles.labelCaption.copyWith(
                            color: AppColors.onSurfaceVariant)),
                    Text(
                      '${Formatters.formatPkr(worker.hourlyRate)} / hr',
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedWorkerId = worker.workerId;
                          _isMapView = true;
                        });
                      },
                      icon: const Icon(Icons.map_outlined, size: 15),
                      label: const Text('Map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      text: AppL10n.select(context, en: 'Book', ur: 'بک'),
                      isSmall: true,
                      onPressed: () => BookingPaymentSheet.show(
                        context,
                        workerId: worker.workerId,
                        workerName: worker.name,
                        categoryName: worker.category,
                        hourlyRatePkr: worker.hourlyRate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ).animate().fade(delay: (60 * index).ms, duration: 400.ms),
    );
  }

  Widget _buildDistanceChip(double distanceKm, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            GeoLocationUtil.formatInDriveDistanceEta(distanceKm),
            style: AppTextStyles.labelCaption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingChip(double rating, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amberWarm.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.amberWarm),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.labelCaption.copyWith(
              color: AppColors.amberWarm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No workers found',
            style: AppTextStyles.heading3.copyWith(
                color: context.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Try increasing the distance or\nchanging the category',
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() {
              _maxDistanceRadiusKm = 5.0;
              _selectedCategory = 'All';
              _minRating = 0.0;
              _availableOnly = false;
            }),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}
