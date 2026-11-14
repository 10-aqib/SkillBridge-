import 'dart:async';

/// Runs tasks one at a time, starting each at least [minGap] after the
/// previous one started. Used for public map services that allow about one
/// request a second (Nominatim, the OSRM demo server). Pure Dart.
class RequestSpacer {
  RequestSpacer(this.minGap, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final Duration minGap;
  final DateTime Function() _clock;
  Future<void> _queue = Future.value();
  DateTime? _last;

  Future<T> run<T>(Future<T> Function() task) {
    final done = Completer<T>();
    _queue = _queue.then((_) async {
      final last = _last;
      if (last != null && minGap > Duration.zero) {
        final wait = minGap - _clock().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _last = _clock();
      try {
        done.complete(await task());
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }
}
