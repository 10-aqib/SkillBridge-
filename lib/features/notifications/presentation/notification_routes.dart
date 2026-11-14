import 'package:skill_bridge/config/router/route_names.dart';

final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

/// Where a notification leads, from its data (in-app list and push taps):
/// a message opens its conversation, a contract update its contract. Ids
/// are checked so a crafted payload can't build another route; the opened
/// screen still checks access (the rules allow only the two people).
String? notificationRouteFor(Map<String, dynamic>? data, {String? type}) {
  if (data == null) return null;
  final chatId = data['chatId']?.toString();
  final contractId = data['contractId']?.toString();
  if ((type == null || type == 'message') && chatId != null && _safeId.hasMatch(chatId)) {
    return RouteNames.chatRoomLocation(chatId);
  }
  if (contractId != null && _safeId.hasMatch(contractId)) return RouteNames.contractDetailsLocation(contractId);
  return null;
}
