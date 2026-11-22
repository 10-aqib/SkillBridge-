import 'package:skill_bridge/generated/l10n/app_localizations.dart';

/// Road distance: 10 m steps up to 300 m, 50 m steps up to a kilometre,
/// then kilometres (one decimal under 10 km).
String formatRouteDistance(AppLocalizations l, num meters) {
  final m = meters.toDouble();
  if (m < 300) return l.navMeters(((m / 10).round() * 10).clamp(0, 300));
  if (m < 1000) return l.navMeters(((m / 50).round() * 50).clamp(300, 1000));
  final km = m / 1000;
  return l.navKilometres(km < 10 ? km.toStringAsFixed(1) : km.round().toString());
}

/// Travel time, rounded up to the minute.
String formatRouteDuration(AppLocalizations l, num seconds) {
  final s = seconds.toDouble();
  if (s < 60) return l.navUnderAMinute;
  final minutes = (s / 60).ceil();
  if (minutes < 60) return l.navMinutes(minutes);
  return l.navHoursMinutes(minutes ~/ 60, minutes % 60);
}
