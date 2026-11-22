import 'dart:async';
import 'dart:js_interop';

import 'package:skill_bridge/core/utils/logger.dart';
import 'package:web/web.dart' as web;

// Web: the Maps JavaScript API is loaded at start-up with its own key
// (`GOOGLE_MAPS_WEB_API_KEY`, restricted by HTTP referrer), so no key is
// ever written into web/index.html. Without a key nothing is loaded.

const _webKey = String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY');

bool get googleMapsKeyConfigured => _webKey.isNotEmpty && _loaded;

bool _loaded = false;
bool _authFailed = false;

/// True once Google rejected the key (wrong referrer, API not enabled,
/// billing off). Maps then show "Map unavailable".
bool get googleMapsAuthFailed => _authFailed;

@JS('gm_authFailure')
external set _gmAuthFailure(JSFunction f);

@JS('__sbMapsReady')
external set _ready(JSFunction f);

/// Loads the Maps JavaScript API once. Returns whether maps can be drawn.
Future<bool> prepareGoogleMaps() async {
  if (_webKey.isEmpty) return false;
  if (_loaded) return true;
  final done = Completer<bool>();
  _gmAuthFailure = (() {
    _authFailed = true;
    Logger.w('[Maps] Google rejected the web Maps key');
  }).toJS;
  _ready = (() {
    if (!done.isCompleted) done.complete(true);
  }).toJS;
  final query = Uri(queryParameters: {
    'key': _webKey,
    'loading': 'async',
    'callback': '__sbMapsReady',
    'v': 'weekly',
  }).query;
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?$query'
    ..async = true
    ..defer = true;
  script.onerror = ((web.Event _) {
    if (!done.isCompleted) done.complete(false);
  }).toJS;
  web.document.head!.append(script);
  _loaded = await done.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
  if (!_loaded) Logger.w('[Maps] Maps JavaScript API did not load');
  return _loaded;
}
