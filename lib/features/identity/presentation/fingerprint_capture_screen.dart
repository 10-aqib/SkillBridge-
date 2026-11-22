import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/features/identity/data/biometric_capture_service.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';
import 'package:skill_bridge/shared/design_system/design_system.dart';

/// Fingerprint capture (FingerprintCaptureScreen). Shows the scanner states
/// and returns the capture to submit, or null when cancelled. A successful
/// capture is NOT a successful identity match: that is decided by NADRA
/// (through the server) on the next screen.
class FingerprintCaptureScreen extends StatefulWidget {
  const FingerprintCaptureScreen({super.key, required this.service, required this.expiresAt});
  final BiometricCaptureService service;
  final DateTime expiresAt;

  @override
  State<FingerprintCaptureScreen> createState() => _FingerprintCaptureScreenState();
}

String captureStateText(AppLocalizations l, CaptureState s) => switch (s) {
      CaptureState.waitingForScanner => l.captureWaiting,
      CaptureState.scannerConnected => l.captureConnected,
      CaptureState.ready => l.captureReady,
      CaptureState.fingerDetected => l.captureFingerDetected,
      CaptureState.capturing => l.captureCapturing,
      CaptureState.success => l.captureSuccess,
      CaptureState.poorQuality => l.capturePoorQuality,
      CaptureState.fingerNotDetected => l.captureNotDetected,
      CaptureState.failed => l.captureFailed,
      CaptureState.scannerDisconnected => l.captureDisconnected,
      CaptureState.sessionExpired => l.captureExpired,
    };

class _FingerprintCaptureScreenState extends State<FingerprintCaptureScreen> {
  CaptureAvailability? _availability;
  CaptureState? _state;
  double _progress = 0;
  CaptureResult? _result;
  StreamSubscription<CaptureEvent>? _sub;

  bool get _busy => _sub != null;
  bool get _expired => DateTime.now().isAfter(widget.expiresAt);

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final a = await widget.service.availability();
    if (mounted) setState(() => _availability = a);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _result = null; // the capture is never kept after this screen
    widget.service.dispose();
    super.dispose();
  }

  void _start() {
    if (_expired) {
      setState(() => _state = CaptureState.sessionExpired);
      return;
    }
    setState(() {
      _result = null;
      _progress = 0;
      _state = CaptureState.waitingForScanner;
    });
    _sub = widget.service.capture().listen((e) {
      if (!mounted) return;
      setState(() {
        _state = e.state;
        _progress = e.progress;
        if (e.state == CaptureState.success) _result = e.result;
      });
    }, onDone: () {
      if (mounted) setState(() => _sub = null);
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _state = CaptureState.failed;
          _sub = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final sb = context.sb;
    final simulated = widget.service.isSimulated;
    final noScanner = _availability == CaptureAvailability.noApprovedSdk;
    final state = _state;
    final problem = state == CaptureState.poorQuality ||
        state == CaptureState.fingerNotDetected ||
        state == CaptureState.failed ||
        state == CaptureState.scannerDisconnected ||
        state == CaptureState.sessionExpired;
    final tone = state == CaptureState.success ? SbTone.success : problem ? SbTone.error : SbTone.info;
    final svc = widget.service;

    return Scaffold(
      appBar: AppBar(title: Text(l.captureTitle)),
      body: ListView(padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s4, SbLayout.edge(context), SbSpace.s8), children: [
        if (simulated) ...[
          SbInlineBanner(message: l.identityTestBanner, tone: SbTone.warning, icon: Icons.science_outlined),
          const SizedBox(height: SbSpace.s4),
        ],
        if (noScanner)
          SbInlineBanner(message: l.captureNoApprovedScanner, tone: SbTone.warning, icon: Icons.usb_off_rounded)
        else ...[
          Center(
            child: Semantics(
              label: state == null ? l.captureInstructions : captureStateText(l, state),
              liveRegion: true,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: sb.tone(tone).background),
                child: Stack(alignment: Alignment.center, children: [
                  if (state == CaptureState.capturing)
                    SizedBox.square(dimension: 150, child: CircularProgressIndicator(value: _progress, strokeWidth: 5)),
                  Icon(
                    state == CaptureState.success ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                    size: 88,
                    color: sb.tone(tone).foreground,
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: SbSpace.s4),
          Text(state == null ? l.captureInstructions : captureStateText(l, state), style: t.titleSmall, textAlign: TextAlign.center),
          if (simulated && svc is SimulatedCaptureService) ...[
            const SizedBox(height: SbSpace.s5),
            Text(l.captureScenario, style: t.labelLarge),
            const SizedBox(height: SbSpace.s2),
            Wrap(spacing: SbSpace.s2, runSpacing: SbSpace.s2, children: [
              for (final (sc, label) in [
                (SimulatedScenario.goodCapture, l.scenarioGood),
                (SimulatedScenario.poorQuality, l.scenarioPoor),
                (SimulatedScenario.fingerNotDetected, l.scenarioNoFinger),
                (SimulatedScenario.scannerDisconnected, l.scenarioDisconnected),
                (SimulatedScenario.captureFails, l.scenarioFails),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: svc.scenario == sc,
                  onSelected: _busy ? null : (_) => setState(() => svc.scenario = sc),
                ),
            ]),
          ],
        ],
      ]),
      // Actions stay in reach on any screen size.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(SbLayout.edge(context), SbSpace.s2, SbLayout.edge(context), SbSpace.s3),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (!noScanner) ...[
              if (_result != null)
                SbButton(label: l.captureSubmit, icon: Icons.send_rounded, expand: true, onPressed: () => Navigator.of(context).pop(_result))
              else
                SbButton(
                  label: state == null ? l.captureStart : l.captureRetry,
                  icon: Icons.fingerprint_rounded,
                  expand: true,
                  isLoading: _busy,
                  onPressed: _busy || state == CaptureState.sessionExpired ? null : _start,
                ),
              const SizedBox(height: SbSpace.s2),
            ],
            SbButton(label: l.cancel, variant: SbButtonVariant.secondary, expand: true, onPressed: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
    );
  }
}
