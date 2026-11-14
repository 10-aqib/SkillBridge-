import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:skill_bridge/core/providers/shared_providers.dart';
import 'package:skill_bridge/core/utils/logger.dart';
import 'package:skill_bridge/features/navigation/domain/announcement_planner.dart';
import 'package:skill_bridge/features/navigation/presentation/nav_text.dart';
import 'package:skill_bridge/features/navigation/presentation/providers/navigation_controller.dart';
import 'package:skill_bridge/generated/l10n/app_localizations.dart';

/// Spoken turn-by-turn directions (Navigation phase 7).
///
/// Words come from the same English/Urdu texts as the screen. Speech uses
/// the device's media volume, asks for audio focus so music ducks under it
/// (Android) and mixes politely with other audio (iOS), and runs only while
/// navigating. Muting is remembered on the device.

/// Text to speech, behind an interface for tests.
abstract class Speaker {
  /// Switches to [languageTag] (e.g. "ur-PK"); false if the device has no
  /// voice for it.
  Future<bool> setLanguage(String languageTag);
  Future<void> speak(String text);
  Future<void> stop();
  void dispose();
}

class FlutterTtsSpeaker implements Speaker {
  FlutterTtsSpeaker() : _tts = FlutterTts();
  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    try {
      // A new instruction replaces one still being spoken (flush).
      await _tts.awaitSpeakCompletion(false);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(kIsWeb ? 0.95 : 0.5);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.duckOthers, IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      }
    } catch (e) {
      Logger.w('[Voice] setup failed: $e');
    }
  }

  @override
  Future<bool> setLanguage(String languageTag) async {
    await _configure();
    try {
      final available = await _tts.isLanguageAvailable(languageTag);
      if (available != true) return false;
      await _tts.setLanguage(languageTag);
      return true;
    } catch (e) {
      Logger.w('[Voice] language $languageTag unavailable: $e');
      return false;
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text, focus: true);
    } catch (e) {
      Logger.w('[Voice] speak failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    stop();
  }
}

final speakerProvider = Provider<Speaker>((ref) {
  final s = FlutterTtsSpeaker();
  ref.onDispose(s.dispose);
  return s;
});

/// Voice guidance muted, remembered on this device.
class VoiceMutedNotifier extends Notifier<bool> {
  static const _key = 'nav_voice_muted';

  @override
  bool build() {
    try {
      return ref.watch(hiveServiceProvider).settingsBox.get(_key) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setMuted(bool muted) async {
    state = muted;
    try {
      await ref.read(hiveServiceProvider).settingsBox.put(_key, muted);
    } catch (_) {}
  }

  Future<void> toggle() => setMuted(!state);
}

final voiceMutedProvider = NotifierProvider<VoiceMutedNotifier, bool>(VoiceMutedNotifier.new);

enum VoiceNotice {
  none,

  /// No Urdu voice on this device: directions are spoken in English.
  englishFallback,

  /// No usable voice at all: directions are on screen only.
  unavailable,
}

@immutable
class VoiceState {
  const VoiceState({this.notice = VoiceNotice.none, this.lastSpoken});
  final VoiceNotice notice;

  /// The last instruction text (spoken, or due while muted).
  final String? lastSpoken;
}

class NavigationVoice extends Notifier<VoiceState> {
  final _planner = AnnouncementPlanner();
  String _languageCode = 'en';
  Future<AppLocalizations?>? _ready;
  AppLocalizations? _words;

  @override
  VoiceState build() {
    ref.listen<NavState>(navigationControllerProvider, _onNav);
    ref.listen<bool>(voiceMutedProvider, (previous, muted) {
      if (muted) {
        _speaker.stop();
      } else if (previous == true) {
        _repeatCurrent();
      }
    });
    final speaker = ref.read(speakerProvider);
    ref.onDispose(speaker.stop);
    return const VoiceState();
  }

  Speaker get _speaker => ref.read(speakerProvider);

  /// The screen's language ('en' or 'ur'); set before guidance starts.
  void setLanguage(String languageCode) {
    if (languageCode == _languageCode && _ready != null) return;
    _languageCode = languageCode == 'ur' ? 'ur' : 'en';
    _ready = null;
  }

  /// How long to wait before asking again when no voice was found: browsers
  /// load their voice list asynchronously, so right after the page opens
  /// it can still be empty.
  static const voicesRetryAfter = Duration(milliseconds: 1500);

  /// Picks a voice for the screen's language (see [_pick]); if nothing was
  /// found, asks once more after [voicesRetryAfter] before giving up.
  Future<AppLocalizations?> _prepare() async {
    final words = await _pick();
    if (words != null) return words;
    await Future<void>.delayed(voicesRetryAfter);
    final again = await _pick();
    if (again == null) state = VoiceState(notice: VoiceNotice.unavailable, lastSpoken: state.lastSpoken);
    return again;
  }

  /// Urdu if installed, else English (with a notice), else none.
  Future<AppLocalizations?> _pick() async {
    if (_languageCode == 'ur') {
      for (final tag in const ['ur-PK', 'ur-IN', 'ur']) {
        if (await _speaker.setLanguage(tag)) return lookupAppLocalizations(const Locale('ur'));
      }
      for (final tag in const ['en-GB', 'en-US', 'en']) {
        if (await _speaker.setLanguage(tag)) {
          state = VoiceState(notice: VoiceNotice.englishFallback, lastSpoken: state.lastSpoken);
          return lookupAppLocalizations(const Locale('en'));
        }
      }
    } else {
      for (final tag in const ['en-GB', 'en-US', 'en']) {
        if (await _speaker.setLanguage(tag)) return lookupAppLocalizations(const Locale('en'));
      }
    }
    return null;
  }

  void _onNav(NavState? previous, NavState next) {
    if (next.status == NavStatus.cancelled || next.status == NavStatus.error) {
      _speaker.stop();
      return;
    }
    final guiding = next.status == NavStatus.navigating || next.status == NavStatus.arrived;
    final progress = next.progress;
    if (!guiding || progress == null) return;
    // Only react to a new position or route, not to unrelated state changes.
    if (identical(previous?.progress, progress) && previous?.routeVersion == next.routeVersion) return;
    final a = _planner.next(progress, routeVersion: next.routeVersion, speed: next.fix?.speed);
    if (a != null) _announce(a, next);
  }

  Future<void> _announce(Announcement a, NavState s) async {
    _ready ??= _prepare().then((w) => _words = w);
    final words = await _ready;
    if (words == null) return;
    final text = sentenceFor(words, a, s);
    if (text == null) return;
    state = VoiceState(notice: state.notice, lastSpoken: text);
    if (ref.read(voiceMutedProvider)) return;
    await _speaker.speak(text);
  }

  /// After unmuting: say the next instruction straight away.
  Future<void> _repeatCurrent() async {
    final s = ref.read(navigationControllerProvider);
    final p = s.progress;
    if (s.status != NavStatus.navigating || p == null) return;
    final words = _words ?? await (_ready ??= _prepare().then((w) => _words = w));
    if (words == null) return;
    final text = sentenceFor(words, Announcement(AnnouncementKind.near, stepIndex: p.nextStepIndex, distance: p.distanceToManeuver), s);
    if (text != null) await _speaker.speak(text);
  }
}

final navigationVoiceProvider = NotifierProvider.autoDispose<NavigationVoice, VoiceState>(NavigationVoice.new);

/// The sentence for [a] in the language of [w], or null.
@visibleForTesting
String? sentenceFor(AppLocalizations w, Announcement a, NavState s) {
  final steps = s.route?.steps ?? const [];
  String mid(String text) => w.localeName.startsWith('en') && text.isNotEmpty ? text[0].toLowerCase() + text.substring(1) : text;
  switch (a.kind) {
    case AnnouncementKind.approaching:
      return w.navSayApproaching;
    case AnnouncementKind.arrived:
      return w.navArrivedTitle;
    case AnnouncementKind.rerouted:
      return w.navRerouted;
    case AnnouncementKind.start:
    case AnnouncementKind.early:
    case AnnouncementKind.near:
    case AnnouncementKind.now:
      final i = a.stepIndex;
      if (i == null || i >= steps.length) return null;
      final step = steps[i];
      final instruction = instructionFor(w, step);
      var text = a.kind == AnnouncementKind.now || a.distance < 30 ? instruction : w.navSayIn(spokenDistance(w, a.distance), mid(instruction));
      // A maneuver right after this one is said together with it.
      if (a.kind != AnnouncementKind.early && i + 1 < steps.length && step.distance < 150) {
        text = w.navSayThen(text, mid(instructionFor(w, steps[i + 1])));
      }
      return text;
  }
}

/// Distance in words for speech ("400 metres", "1.5 kilometres").
String spokenDistance(AppLocalizations w, double meters) {
  if (meters < 1000) {
    final step = meters < 300 ? 10 : 50;
    final rounded = ((meters / step).round() * step).clamp(10, 1000).toInt();
    if (rounded >= 1000) return w.navSpeakKilometres('1');
    return w.navSpeakMeters(rounded);
  }
  final km = meters / 1000;
  return w.navSpeakKilometres(km < 10 ? km.toStringAsFixed(1) : km.round().toString());
}
