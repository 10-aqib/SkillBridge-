import 'package:skill_bridge/core/utils/app_l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:skill_bridge/features/auth/data/models/user_model.dart';
import 'package:skill_bridge/features/client/presentation/providers/nearby_workers_provider.dart';
import 'package:skill_bridge/features/client/presentation/widgets/home_drawer.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

// ignore_for_file: unused_import

/// Skill Bridge — Refined Home Screen (UI improvements batch)
/// - Single Popular Services grid (6 items, 3 cols) with All Services link.
/// - Compact hero banner (reduced height/padding).
/// - Material icons on section headers (no emoji).
/// - Banner renamed from "Featured Deals" to "Featured Services".
/// - Service assistance card.
/// - Live worker recommendations grouped by trade.
class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});
  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SearchController _searchController = SearchController();
  String _selectedCity = 'Islamabad';
  int _currentBanner = 0;
  late PageController _pageController;
  late PageController _workerPageController;
  int _currentWorkerPage = 0;
  late AnimationController _heroAnim;
  Timer? _timer;

  static const List<String> _allServices = [
    'Electrician',
    'Plumber',
    'AC Repair',
    'Carpenter',
    'Painter',
    'Home Cleaning',
    'Mason',
    'Welder',
    'Tiles Fixer',
    'Roof Fixer',
    'Generator Repair',
    'Water Pump',
    'Gate Maker',
    'Gardener',
    'Security Camera',
    'Sofa Repair',
    'Geyser Repair',
    'Lift Mechanic',
    'Pest Control',
    'Curtain Fixer',
    'Driver',
    'Cook',
    'Baby Sitter',
    'CCTV Installation',
    'Solar Panel',
    'Internet Setup',
    'Tutor',
  ];

  static const int _popularCategoryCount = 6;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Expert Electricians',
      'subtitle': 'On-demand service across Pakistan',
      'color1': const Color(0xFF001E60),
      'color2': const Color(0xFF0066FF),
      'image': 'assets/images/banner_electrician.jpg',
      'icon': Icons.electrical_services_rounded,
    },
    {
      'title': 'Home Cleaning',
      'subtitle': 'Professional deep clean services',
      'color1': const Color(0xFF004D35),
      'color2': const Color(0xFF00A86B),
      'image': 'assets/images/banner_cleaning.jpg',
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'title': 'AC & HVAC Service',
      'subtitle': 'Certified technicians near you',
      'color1': const Color(0xFF4A0070),
      'color2': const Color(0xFF9C27B0),
      'image': 'assets/images/banner_ac_repair.jpg',
      'icon': Icons.ac_unit_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null &&
        user.city != null &&
        PakistanConstants.majorCities.contains(user.city)) {
      _selectedCity = user.city!;
    }
    _pageController = PageController(viewportFraction: 0.92);
    _workerPageController = PageController(viewportFraction: 1);
    _heroAnim = AnimationController(vsync: this, duration: 600.ms)..forward();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentBanner + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: 500.ms,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _workerPageController.dispose();
    _heroAnim.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getSuggestions(String query) {
    if (query.isEmpty) return _allServices.take(6).toList();
    final q = query.toLowerCase();
    return _allServices.where((s) => s.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.formattedDisplayName ?? 'Client').split(' ').first;
    final popularCategories = PakistanConstants.categories
        .take(_popularCategoryCount)
        .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.scaffoldBg,
        drawer: const HomeDrawer(),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroHeader(context, firstName)),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.lg)),

            // Popular Services (up to 6) + All Services link
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                icon: Icons.star_rounded,
                title: 'Popular Services',
                action: 'All Services',
                onAction: () =>
                    context.push(RouteNames.clientNearbyWorkersPath),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
            SliverToBoxAdapter(
              child: _buildPopularServicesGrid(context, popularCategories),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // Featured Services banner (not "Featured Deals")
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                icon: Icons.local_offer_rounded,
                title: 'Featured Services',
                action: null,
                onAction: null,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
            SliverToBoxAdapter(child: _buildBannerCarousel(context)),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // Service assistance card
            SliverToBoxAdapter(child: _buildServiceAssistanceCard(context)),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            // Real worker profiles, one card at a time on mobile.
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context,
                icon: Icons.people_rounded,
                title: 'You Might Need',
                action: 'See All',
                onAction: () =>
                    context.push(RouteNames.clientNearbyWorkersPath),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.md)),
            SliverToBoxAdapter(child: _buildYouMightNeed(context, ref)),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),

            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copyright_rounded,
                        size: 14,
                        color: context.mutedColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Skill Bridge \u00b7 All rights reserved 2026',
                        style: AppTextStyles.labelStatus.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, String firstName) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_workers_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF001E60)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF0001E60),
                    Color(0xCC003FB1),
                    Color(0x66001E60),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Semantics(
                        label: 'Open menu',
                        button: true,
                        child: GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCity,
                                isDense: true,
                                dropdownColor: const Color(0xFF003FB1),
                                style: AppTextStyles.labelStatus.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                items: PakistanConstants.majorCities
                                    .take(6)
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
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
                      Semantics(
                        label: 'View notifications',
                        button: true,
                        child: GestureDetector(
                          onTap: () =>
                              context.push(RouteNames.clientNotificationsPath),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                        'Hello, $firstName \ud83d\udc4b',
                        style: AppTextStyles.labelCaption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 2),
                  Text(
                    'What service do you need?',
                    style: AppTextStyles.heading2.copyWith(
                      color: Colors.white,
                      height: 1.2,
                      fontSize: 20,
                    ),
                  ).animate().fade(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  _buildSearchBar(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            tooltip: 'Close search',
            onPressed: () => _searchController.closeView(null),
          ),
          viewHintText: 'Search for a service or worker...',
          builder: (context, controller) {
            return Semantics(
              label: 'Search services and workers',
              button: true,
              child: GestureDetector(
                onTap: () => controller.openView(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
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
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.text.isEmpty
                              ? 'Search for a service or worker...'
                              : controller.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: controller.text.isEmpty
                                ? context.mutedColor
                                : context.textColor,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.borderColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: context.mutedColor,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          suggestionsBuilder: (context, controller) {
            final results = _getSuggestions(controller.text);
            final query = controller.text;
            return [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  query.isEmpty ? 'Popular Services' : 'Results for "$query"',
                  style: AppTextStyles.labelStatus.copyWith(
                    color: context.mutedColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
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
                    child: const Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(service, style: AppTextStyles.bodyStrong),
                  subtitle: Text(
                    _selectedCity,
                    style: AppTextStyles.labelStatus.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: context.mutedColor,
                  ),
                  onTap: () {
                    controller.closeView(service);
                    context.push(RouteNames.clientNearbyWorkersPath);
                  },
                ),
              ),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: context.borderColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No services found for "$query"',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try electrician, plumber, or AC repair',
                        style: AppTextStyles.labelStatus.copyWith(
                          color: context.mutedColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ];
          },
        )
        .animate()
        .fade(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String? action,
    required VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading3.copyWith(
                      color: context.textColor,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(width: AppDimensions.sm),
            Semantics(
              label: action,
              button: true,
              child: GestureDetector(
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Text(
                    action,
                    style: AppTextStyles.labelCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPopularServicesGrid(
    BuildContext context,
    List<Map<String, dynamic>> cats,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final cat = cats[index];
          return _buildPopularServiceItem(
            context,
            icon: cat['icon'] as IconData,
            name: cat['name'] as String,
            index: index,
          );
        },
      ),
    );
  }

  Widget _buildPopularServiceItem(
    BuildContext context, {
    required IconData icon,
    required String name,
    required int index,
  }) {
    final color = AppColors.getCategoryColor(name);
    return Semantics(
      label: 'Find $name workers',
      button: true,
      child: GestureDetector(
        onTap: () => context.push(RouteNames.clientNearbyWorkersPath),
        child:
            Container(
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: context.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          name,
                          style: AppTextStyles.labelStatus.copyWith(
                            color: context.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fade(delay: (40 * index).ms, duration: 300.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                ),
      ),
    );
  }

  Widget _buildServiceAssistanceCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.blueTint,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Not sure which service?',
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Browse all categories to find the right worker.',
                    style: AppTextStyles.labelStatus.copyWith(
                      color: context.mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Browse all service categories',
              button: true,
              child: GestureDetector(
                onTap: () => context.push(RouteNames.clientNearbyWorkersPath),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    'Browse',
                    style: AppTextStyles.labelStatus.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYouMightNeed(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(youMightNeedWorkersProvider);
    return workersAsync.when(
      loading: () => const _WorkerCardSkeleton(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
        child: _workerSectionMessage(
          context,
          icon: Icons.cloud_off_outlined,
          title: 'Workers could not be loaded',
          message: 'Check your connection and try again.',
          action: 'Retry',
          onAction: () => ref.invalidate(youMightNeedWorkersProvider),
        ),
      ),
      data: (workers) {
        if (workers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: _workerSectionMessage(
              context,
              icon: Icons.person_search_outlined,
              title: 'No worker profiles yet',
              message:
                  'Worker profiles will appear here when workers publish their services.',
              action: 'Browse categories',
              onAction: () => context.push(RouteNames.clientNearbyWorkersPath),
            ),
          );
        }

        final page = _currentWorkerPage.clamp(0, workers.length - 1);
        return Column(
          children: [
            SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _workerPageController,
                itemCount: workers.length,
                onPageChanged: (index) =>
                    setState(() => _currentWorkerPage = index),
                itemBuilder: (context, index) =>
                    _workerRecommendationCard(context, workers[index]),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (workers.length > 1)
                  ...List.generate(
                    workers.length,
                    (index) => AnimatedContainer(
                      duration: 180.ms,
                      width: index == page ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == page
                            ? AppColors.primary
                            : context.borderColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                if (workers.length > 1) const SizedBox(width: AppDimensions.sm),
                Text(
                  '${page + 1} / ${workers.length}',
                  style: AppTextStyles.labelCaption.copyWith(
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _workerRecommendationCard(BuildContext context, UserModel worker) {
    final profile = worker.workerProfile!;
    final imageUrl = (profile.coverImage?.trim().isNotEmpty ?? false)
        ? profile.coverImage
        : worker.photoUrl;
    final city = profile.city.trim().isNotEmpty
        ? profile.city.trim()
        : worker.city?.trim() ?? '';
    final reviewCount = profile.totalReviews > 0
        ? profile.totalReviews
        : worker.totalReviews;
    final rating = profile.totalReviews > 0
        ? profile.averageRating
        : worker.rating;
    final rate = profile.hourlyRate > 0
        ? 'Rs. ${profile.hourlyRate.toStringAsFixed(0)} / hour'
        : profile.dailyRate > 0
        ? 'Rs. ${profile.dailyRate.toStringAsFixed(0)} / day'
        : 'Rate on request';
    final availability = switch (profile.availability.toLowerCase()) {
      'available' => 'Available',
      'busy' => 'Busy',
      _ => 'Unavailable',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg / 2),
      child: Material(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.pushNamed(
            RouteNames.publicWorkerProfileName,
            pathParameters: {'workerId': worker.uid},
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 144,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _workerImageFallback(),
                        )
                      else
                        _workerImageFallback(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.22),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppDimensions.md,
                        left: AppDimensions.md,
                        child: _workerPill(context, profile.categoryName),
                      ),
                      Positioned(
                        right: AppDimensions.md,
                        bottom: AppDimensions.md,
                        child: _workerPill(context, availability),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.md,
                      AppDimensions.sm,
                      AppDimensions.md,
                      AppDimensions.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                worker.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading3.copyWith(
                                  color: context.textColor,
                                ),
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: AppDimensions.xs),
                              Icon(
                                Icons.verified_rounded,
                                size: 17,
                                color: AppColors.primary,
                                semanticLabel: 'SkillBridge reviewed profile',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.headline.trim().isNotEmpty
                              ? profile.headline.trim()
                              : profile.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: context.mutedColor,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppDimensions.xs),
                            Expanded(
                              child: Text(
                                rate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (reviewCount > 0) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.amber,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: context.textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                ' ($reviewCount)',
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: context.mutedColor,
                                ),
                              ),
                            ] else
                              Text(
                                'New profile',
                                style: AppTextStyles.labelCaption.copyWith(
                                  color: context.mutedColor,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: context.mutedColor,
                            ),
                            const SizedBox(width: AppDimensions.xs),
                            Expanded(
                              child: Text(
                                city.isEmpty ? 'Service area not listed' : city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: context.mutedColor,
                                ),
                              ),
                            ),
                            Text(
                              'View full profile',
                              style: AppTextStyles.labelStatus.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _workerImageFallback() {
    return Container(
      color: AppColors.blueTint,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.primary,
        size: 48,
      ),
    );
  }

  Widget _workerPill(BuildContext context, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelStatus.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _workerSectionMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: context.textColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  message,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: context.mutedColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(action),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final b = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (b['color1'] as Color).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      b['image'] as String,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) =>
                          Container(color: b['color1'] as Color),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            (b['color1'] as Color).withValues(alpha: 0.97),
                            (b['color1'] as Color).withValues(alpha: 0.85),
                            (b['color2'] as Color).withValues(alpha: 0.25),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  b['icon'] as IconData,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  b['title'] as String,
                                  style: AppTextStyles.heading3.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 200,
                              child: Text(
                                b['subtitle'] as String,
                                style: AppTextStyles.labelStatus.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              label: 'Find ${b['title']} workers',
                              button: true,
                              child: GestureDetector(
                                onTap: () => context.push(
                                  RouteNames.clientNearbyWorkersPath,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Find Workers',
                                        style: AppTextStyles.labelStatus
                                            .copyWith(
                                              color: b['color1'] as Color,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 13,
                                        color: b['color1'] as Color,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBanner == i ? 18 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: _currentBanner == i
                    ? AppColors.primary
                    : context.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder in the shape of the recommended-worker card (photo, name,
/// title, rate line, buttons) and its page dots, so nothing moves when the
/// real cards arrive.
class _WorkerCardSkeleton extends StatelessWidget {
  const _WorkerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SbSkeletonGroup(
      child: Column(children: [
        SizedBox(
          height: 340,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg / 2),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border.all(color: context.borderColor),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SbSkeleton(height: 144, radius: 0),
                Padding(
                  padding: EdgeInsets.all(AppDimensions.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SbSkeleton(width: 160, height: 18),
                    SizedBox(height: SbSpace.s2),
                    SbSkeleton(width: 120, height: 12),
                    SizedBox(height: SbSpace.s4),
                    Row(children: [
                      SbSkeleton(width: 90, height: 14),
                      SizedBox(width: SbSpace.s4),
                      SbSkeleton(width: 70, height: 14),
                    ]),
                    SizedBox(height: SbSpace.s4),
                    Row(children: [
                      Expanded(child: SbSkeleton(height: 40, radius: SbRadius.control)),
                      SizedBox(width: SbSpace.s3),
                      Expanded(child: SbSkeleton(height: 40, radius: SbRadius.control)),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SbSkeleton(width: 18, height: 6, radius: 99),
          SizedBox(width: 6),
          SbSkeleton(width: 6, height: 6, radius: 99),
          SizedBox(width: 6),
          SbSkeleton(width: 6, height: 6, radius: 99),
        ]),
      ]),
    );
  }
}
