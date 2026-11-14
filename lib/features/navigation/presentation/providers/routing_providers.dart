import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/core/map/map_config.dart';
import 'package:skill_bridge/features/navigation/data/osrm_routing_service.dart';
import 'package:skill_bridge/features/navigation/data/routing_service.dart';

/// The routing engine from the build-time settings (Navigation phase 5).
/// Overridden in tests.
final routingServiceProvider = Provider<RoutingService>((ref) {
  final config = ref.watch(routingConfigProvider);
  if (!config.isValid) return const UnavailableRoutingService();
  final service = OsrmRoutingService(
    baseUrl: config.baseUrl,
    profile: config.profile,
    userAgent: 'SkillBridge/1.0 ($appUserAgentPackage)',
  );
  ref.onDispose(service.dispose);
  return service;
});
