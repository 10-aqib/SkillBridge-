import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/router/route_names.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/client/presentation/widgets/home_drawer.dart';

/// Skill Bridge — Enhanced "Pro Gradient" Home Screen
/// Features: Worker background image in hero, live search with suggestions,
///           real worker images in Featured Deals banners
class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SearchController _searchController = SearchController();
  String _selectedCity = 'Lahore';
  int _currentBanner = 0;
  late PageController _pageController;
  late AnimationController _heroAnim;
  Timer? _timer;

  // ── All searchable services ─────────────────────────────────────────────────
  static const List<String> _allServices = [
    'Electrician', 'Plumber', 'AC Repair', 'Carpenter', 'Painter',
    'Home Cleaning', 'Mason', 'Welder', 'Tiles Fixer', 'Roof Fixer',
    'Generator Repair', 'Water Pump', 'Gate Maker', 'Gardener',
    'Security Camera', 'Sofa Repair', 'Geyser Repair', 'Lift Mechanic',
    'Pest Control', 'Curtain Fixer', 'Driver', 'Cook', 'Baby Sitter',
    'CCTV Installation', 'Solar Panel', 'Internet Setup', 'Tutor',
  ];

  // ── Banners with background images ──────────────────────────────────────────
  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Expert Electricians',
      'subtitle': 'On-demand, 24/7 across Pakistan',
      'color1': const Color(0xFF001E60),
      'color2': const Color(0xFF0066FF),
      'image': 'assets/images/banner_electrician.jpg',
      'icon': Icons.electric_bolt_rounded,
      'tag': '⚡ Top Rated',
      'rating': 4.9,
      'jobsCompleted': 120,
      'startingPrice': 500,
    },
    {
      'title': 'Home Cleaning',
      'subtitle': 'Professional deep clean services',
      'color1': const Color(0xFF004D35),
      'color2': const Color(0xFF00A86B),
      'image': 'assets/images/banner_cleaning.jpg',
      'icon': Icons.cleaning_services_rounded,
      'tag': '✨ Premium',
      'rating': 4.8,
      'startingPrice': 1500,
    },
    {
      'title': 'AC & HVAC Repair',
      'subtitle': 'Certified technicians near you',
      'color1': const Color(0xFF4A0070),
      'color2': const Color(0xFF9C27B0),
      'image': 'assets/images/banner_ac_repair.jpg',
      'icon': Icons.ac_unit_rounded,
      'tag': '❄️ Verified',
      'jobsCompleted': 85,
    },
  ];

  static const List<Map<String, dynamic>> _quickServices = [
    {'label': 'Electrician', 'icon': Icons.electric_bolt_rounded, 'color': Color(0xFF003FB1)},
    {'label': 'Plumber', 'icon': Icons.plumbing_rounded, 'color': Color(0xFF006F4B)},
    {'label': 'AC Repair', 'icon': Icons.ac_unit_rounded, 'color': Color(0xFFF59E0B)},
    {'label': 'Carpenter', 'icon': Icons.carpenter_rounded, 'color': Color(0xFF4059AA)},
    {'label': 'Painter', 'icon': Icons.format_paint_rounded, 'color': Color(0xFF7E22CE)},
    {'label': 'Cleaner', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF0284C7)},
    {'label': 'Mason', 'icon': Icons.construction_rounded, 'color': Color(0xFFD97706)},
    {'label': 'More', 'icon': Icons.apps_rounded, 'color': Color(0xFF64748B)},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _heroAnim = AnimationController(vsync: this, duration: 600.ms)..forward();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentBanner + 1) % _banners.length;
      _pageController.animateToPage(next,
          duration: 500.ms, curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _heroAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getSuggestions(String query) {
    if (query.isEmpty) return _allServices.take(6).toList();
    final q = query.toLowerCase();
    return _allServices
        .where((s) => s.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.displayName ?? 'Guest').split(' ').first;
    final categories = PakistanConstants.categories;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.scaffoldBg,
      drawer: const HomeDrawer(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header with Worker Background ────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeroHeader(context, firstName),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.lg)),

          // ── Quick Service Grid ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, '🛠️ Quick Services', null),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
          SliverToBoxAdapter(
            child: _buildQuickServicesGrid(context),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

          // ── Promotional Banner Carousel ───────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, '🔥 Featured Deals', 'See All'),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
          SliverToBoxAdapter(
            child: _buildBannerCarousel(context),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

          // ── All Services Grid ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, '📋 All Services', null),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = categories[index];
                  return _buildServiceCard(
                    context,
                    icon: cat['icon'] as IconData,
                    name: cat['name'] as String,
                    index: index,
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Hero Header ─────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context, String firstName) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image layer
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_workers_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          // Dark gradient overlay on top of image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF0001E60), // ~94% opaque dark blue on left
                    Color(0xCC003FB1), // ~80% opaque mid blue
                    Color(0x66001E60), // ~40% opaque on right (lets image show)
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.menu_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCity,
                                isDense: true,
                                dropdownColor: const Color(0xFF003FB1),
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 16),
                                items: [
                                  'Lahore',
                                  'Islamabad',
                                  'Karachi',
                                  'Rawalpindi',
                                  'Faisalabad'
                                ]
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedCity = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Greeting
                  Text(
                    'Hello, $firstName 👋',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ).animate().fade(duration: 400.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    'What service do\nyou need today?',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ).animate().fade(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 22),
                  // ── Live Search Bar ──────────────────────────────────────
                  _buildSearchBar(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Functional Search Bar with Suggestions ──────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return SearchAnchor(
      searchController: _searchController,
      viewElevation: 8,
      viewBackgroundColor: context.surfaceColor,
      viewShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      viewLeading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => _searchController.closeView(null),
      ),
      viewHintText: 'Search electrician, plumber...',
      builder: (context, controller) {
        return GestureDetector(
          onTap: () => controller.openView(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty
                        ? 'Search electrician, plumber...'
                        : controller.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: controller.text.isEmpty
                          ? AppColors.onSurfaceVariant
                          : AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: AppColors.onSurfaceVariant, size: 16),
                ),
              ],
            ),
          ),
        );
      },
      suggestionsBuilder: (context, controller) {
        final results = _getSuggestions(controller.text);
        final query = controller.text;

        return [
          // "Popular" or "Results for X" header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              query.isEmpty ? '🔥 Popular Services' : '🔍 Results for "$query"',
              style: AppTextStyles.labelCaption.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...results.map(
            (service) => ListTile(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.build_circle_outlined,
                    color: AppColors.primary, size: 20),
              ),
              title: Text(service, style: AppTextStyles.bodyStrong),
              subtitle: Text(
                '$_selectedCity • Skilled workers available',
                style: AppTextStyles.labelCaption.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.onSurfaceVariant),
              onTap: () {
                controller.closeView(service);
                context.push(RouteNames.clientNearbyWorkersPath);
              },
            ),
          ),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 48, color: AppColors.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No services found for "$query"',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
    ).animate().fade(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
      BuildContext context, String title, String? action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: context.textColor,
              fontSize: 17,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: () => context.push(RouteNames.clientNearbyWorkersPath),
              child: Text(
                action,
                style: AppTextStyles.labelCaption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Quick Services Horizontal Scroll ─────────────────────────────────────
  Widget _buildQuickServicesGrid(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
        itemCount: _quickServices.length,
        itemBuilder: (context, index) {
          final svc = _quickServices[index];
          return GestureDetector(
            onTap: () => context.push(RouteNames.clientNearbyWorkersPath),
            child: Container(
              width: 78,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color:
                          (svc['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            (svc['color'] as Color).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(svc['icon'] as IconData,
                        color: svc['color'] as Color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    svc['label'] as String,
                    style: AppTextStyles.labelCaption.copyWith(
                      color: context.textColor,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
                .animate()
                .fade(delay: (50 * index).ms, duration: 350.ms)
                .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0)),
          );
        },
      ),
    );
  }

  // ── Featured Deals Banner with Worker Images ──────────────────────────────
  Widget _buildBannerCarousel(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 178,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final b = _banners[index];
              return AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (b['color1'] as Color).withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Worker background image
                    Image.asset(
                      b['image'] as String,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => Container(
                        color: b['color1'] as Color,
                      ),
                    ),
                    // Gradient overlay from left
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            (b['color1'] as Color).withValues(alpha: 0.97),
                            (b['color1'] as Color).withValues(alpha: 0.88),
                            (b['color2'] as Color).withValues(alpha: 0.3),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    // Text content on left side
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                b['tag'] as String,
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b['title'] as String,
                              style: AppTextStyles.heading3.copyWith(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              width: 220,
                              child: Text(
                                b['subtitle'] as String,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (b['rating'] != null) ...[
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    b['rating'].toString(),
                                    style: AppTextStyles.labelCaption.copyWith(color: Colors.white, fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (b['jobsCompleted'] != null) ...[
                                  const Icon(Icons.task_alt_rounded, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${b['jobsCompleted']}+ done',
                                    style: AppTextStyles.labelCaption.copyWith(color: Colors.white, fontSize: 11),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (b['startingPrice'] != null) ...[
                                  Text(
                                    'Rs ${b['startingPrice']} up',
                                    style: AppTextStyles.labelCaption.copyWith(
                                      color: Colors.white, 
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => context
                                  .push(RouteNames.clientNearbyWorkersPath),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.15),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Book Now',
                                      style:
                                          AppTextStyles.labelCaption.copyWith(
                                        color: b['color1'] as Color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: b['color1'] as Color),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBanner == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBanner == i
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── All Services Card ──────────────────────────────────────────────────────
  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String name,
    required int index,
  }) {
    final color = AppColors.getCategoryColor(name);
    return GestureDetector(
      onTap: () => context.push(RouteNames.clientNearbyWorkersPath),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(child: Icon(icon, color: color, size: 28)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: context.textColor,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Available',
                        style: AppTextStyles.labelCaption.copyWith(
                          color: AppColors.successGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: context.mutedColor),
            ),
          ],
        ),
      )
          .animate()
          .fade(delay: (40 * index).ms, duration: 350.ms)
          .slideX(begin: 0.05, end: 0),
    );
  }
}
