import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fingerprint capture (BiometricCaptureService).
///
/// NADRA verification needs a fingerprint captured by an **approved scanner
/// or capture SDK**. A phone's own fingerprint sensor is not one: it only
/// unlocks the phone and never gives an image NADRA can match. So the app
/// never uses `local_auth` or device biometrics here.
///
/// Implementations:
/// * [NoApprovedCaptureService]: used until NADRA approves a capture SDK or
///   device for SkillBridge. It reports "no approved scanner" and captures
///   nothing.
/// * [SimulatedCaptureService]: test environment only (the server says the
///   provider is the simulator). It captures nothing real: it plays out
///   scanner states and returns a placeholder reference.
/// * The approved SDK adapter goes here once NADRA names the SDK, its
///   platform channel or plugin, and its output format. Nothing about it is
///   assumed in advance.

enum CaptureAvailability { noApprovedSdk, scannerDisconnected, ready }

enum CaptureState {
  waitingForScanner,
  scannerConnected,
  ready,
  fingerDetected,
  capturing,
  success,
  poorQuality,
  fingerNotDetected,
  failed,
  scannerDisconnected,
  sessionExpired,
}

/// What a successful capture hands to the server. [payload] is the SDK's
/// opaque output: held in memory only, sent once, never stored or logged.
class CaptureResult {
  const CaptureResult({required this.format, required this.payload, this.quality});
  final String format;
  final String payload;
  final int? quality;

  Map<String, Object?> toRequest() => {'format': format, 'payload': payload, 'quality': ?quality};
}

class CaptureEvent {
  const CaptureEvent(this.state, {this.progress = 0, this.result});
  final CaptureState state;
  final double progress;
  final CaptureResult? result;
}

abstract class BiometricCaptureService {
  /// Whether an approved capture device/SDK can be used now.
  Future<CaptureAvailability> availability();

  /// One capture attempt, as a stream of states ending in success or a problem.
  Stream<CaptureEvent> capture();

  /// Releases the scanner and clears any temporary capture data.
  Future<void> dispose();

  /// True for the test simulator (UI shows TEST everywhere).
  bool get isSimulated;
}

/// No approved capture SDK/device yet: nothing is captured.
class NoApprovedCaptureService implements BiometricCaptureService {
  const NoApprovedCaptureService();
  @override
  bool get isSimulated => false;
  @override
  Future<CaptureAvailability> availability() async => CaptureAvailability.noApprovedSdk;
  @override
  Stream<CaptureEvent> capture() => Stream.value(const CaptureEvent(CaptureState.scannerDisconnected));
  @override
  Future<void> dispose() async {}
}

/// Scenarios the tester can pick in test mode.
enum SimulatedScenario { goodCapture, poorQuality, fingerNotDetected, scannerDisconnected, captureFails }

/// Test-only scanner: no real fingerprint is read.
class SimulatedCaptureService implements BiometricCaptureService {
  SimulatedCaptureService({this.scenario = SimulatedScenario.goodCapture, this.step = const Duration(milliseconds: 350), Random? random})
      : _random = random ?? Random();

  SimulatedScenario scenario;
  final Duration step;
  final Random _random;
  bool _disposed = false;

  @override
  bool get isSimulated => true;

  @override
  Future<CaptureAvailability> availability() async =>
      scenario == SimulatedScenario.scannerDisconnected ? CaptureAvailability.scannerDisconnected : CaptureAvailability.ready;

  @override
  Stream<CaptureEvent> capture() async* {
    _disposed = false;
    Future<void> pause() => Future<void>.delayed(step);
    yield const CaptureEvent(CaptureState.waitingForScanner);
    await pause();
    if (scenario == SimulatedScenario.scannerDisconnected) {
      yield const CaptureEvent(CaptureState.scannerDisconnected);
      return;
    }
    yield const CaptureEvent(CaptureState.scannerConnected);
    await pause();
    yield const CaptureEvent(CaptureState.ready);
    await pause();
    if (scenario == SimulatedScenario.fingerNotDetected) {
      yield const CaptureEvent(CaptureState.fingerNotDetected);
      return;
    }
    yield const CaptureEvent(CaptureState.fingerDetected);
    for (var i = 1; i <= 4; i++) {
      await pause();
      if (_disposed) return;
      yield CaptureEvent(CaptureState.capturing, progress: i / 4);
    }
    if (scenario == SimulatedScenario.captureFails) {
      yield const CaptureEvent(CaptureState.failed);
      return;
    }
    if (scenario == SimulatedScenario.poorQuality) {
      // Capture SDKs score quality on the device; a poor scan is retaken
      // before anything is sent.
      yield const CaptureEvent(CaptureState.poorQuality);
      return;
    }
    final ref = 'SIMULATED-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1 << 20)}';
    yield CaptureEvent(CaptureState.success, progress: 1, result: CaptureResult(format: 'simulated', payload: ref, quality: 85 + _random.nextInt(10)));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}

/// The capture service for a provider: the simulator only when the server
/// itself runs the test simulator; otherwise no approved capture yet.
final biometricCaptureServiceProvider = Provider.family<BiometricCaptureService, String?>((ref, provider) {
  final service = provider == 'simulator' ? SimulatedCaptureService() : const NoApprovedCaptureService();
  ref.onDispose(service.dispose);
  return service;
});
