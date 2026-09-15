/// RELIABILITY BATCH 2A — Fix 1 / Fix 3 / Fix 4.
///
/// The Settings layer must never persist a setting that claims a live
/// audio/voice effect applied when it actually did not. These tests drive
/// [SettingsNotifier.saveSettings] with a controllable fake
/// [OraclySoundService] / [OraclyTtsPort] so both the success and the
/// failure path are exercised deterministically.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake with independently controllable ambient/sign outcomes — lets a
/// test force a real failure without depending on the platform plugin.
class _ControllableSound extends OraclySoundService {
  bool ambientShouldFail = false;
  bool signShouldFail = false;
  final ambientCalls = <bool>[];
  final signCalls = <ZodiacSignId>[];

  @override
  Future<OraclyApplyOutcome> setAtmosphere(ZodiacSignId sign) async {
    signCalls.add(sign);
    return signShouldFail
        ? OraclyApplyOutcome.failure
        : OraclyApplyOutcome.success;
  }

  @override
  Future<OraclyApplyOutcome> syncAmbientEnabled(bool enabled) async {
    ambientCalls.add(enabled);
    return ambientShouldFail
        ? OraclyApplyOutcome.failure
        : OraclyApplyOutcome.success;
  }

  @override
  Future<void> dispose() async {}
}

/// Throws the moment Settings tries to bind it — simulates a broken TTS
/// engine without needing a real platform channel.
class _ThrowingTts implements OraclyTtsPort {
  @override
  set onSpeakingChanged(void Function(bool isSpeaking)? value) {
    throw StateError('tts bind failed');
  }

  @override
  void Function(bool isSpeaking)? get onSpeakingChanged => null;

  @override
  bool get isSpeaking => false;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(
    _ControllableSound sound, {
    OraclyTtsPort? tts,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclySoundServiceProvider.overrideWithValue(sound),
        if (tts != null) oraclyTtsProvider.overrideWithValue(tts),
      ],
    );
    await container.read(settingsProvider.future);
    return container;
  }

  group('Fix 1 — ambient music honesty', () {
    test('successful enable persists ambient ON', () async {
      final sound = _ControllableSound();
      final container = await containerWith(sound);
      addTearDown(container.dispose);
      addTearDown(sound.dispose);

      final result = await container
          .read(settingsProvider.notifier)
          .saveSettings(const PersonalizationSettings(ambientMusicEnabled: true));

      expect(result.hasFailure, isFalse);
      expect(result.settings.ambientMusicEnabled, isTrue);
      expect(
        container.read(settingsProvider).value?.ambientMusicEnabled,
        isTrue,
      );
    });

    test('successful disable persists ambient OFF', () async {
      final sound = _ControllableSound();
      final container = await containerWith(sound);
      addTearDown(container.dispose);
      addTearDown(sound.dispose);

      await container
          .read(settingsProvider.notifier)
          .saveSettings(const PersonalizationSettings(ambientMusicEnabled: true));
      final result = await container
          .read(settingsProvider.notifier)
          .saveSettings(
            const PersonalizationSettings(ambientMusicEnabled: false),
          );

      expect(result.hasFailure, isFalse);
      expect(result.settings.ambientMusicEnabled, isFalse);
      expect(sound.ambientCalls.last, isFalse);
    });

    test(
      'playback-start failure never leaves the persisted setting falsely ON',
      () async {
        final sound = _ControllableSound()..ambientShouldFail = true;
        final container = await containerWith(sound);
        addTearDown(container.dispose);
        addTearDown(sound.dispose);
        // Discard the passive cold-start restore call (ambient OFF, the
        // model default) so the assertion below only sees this save.
        sound.ambientCalls.clear();

        final result = await container
            .read(settingsProvider.notifier)
            .saveSettings(
              const PersonalizationSettings(ambientMusicEnabled: true),
            );

        expect(result.ambientFailed, isTrue);
        expect(result.settings.ambientMusicEnabled, isFalse);
        // The corrective revert call actually happened, not just the model.
        expect(sound.ambientCalls, [true, false]);
        // The persisted/notifier state matches the honest, corrected value.
        expect(
          container.read(settingsProvider).value?.ambientMusicEnabled,
          isFalse,
        );
      },
    );

    test(
      'FOLLOW-UP 2A: playing ON -> disable -> stop failure -> stays honestly ON',
      () async {
        final sound = _ControllableSound();
        final container = await containerWith(sound);
        addTearDown(container.dispose);
        addTearDown(sound.dispose);

        // Get to a genuinely-applied ON state first (this call succeeds).
        await container
            .read(settingsProvider.notifier)
            .saveSettings(
              const PersonalizationSettings(ambientMusicEnabled: true),
            );

        // Now the user turns it OFF, but the stop attempt fails.
        sound.ambientShouldFail = true;
        final result = await container
            .read(settingsProvider.notifier)
            .saveSettings(
              const PersonalizationSettings(ambientMusicEnabled: false),
            );

        expect(result.ambientFailed, isTrue);
        // Stop was never proven to have worked — must not claim OFF while
        // playback may still be audible.
        expect(result.settings.ambientMusicEnabled, isTrue);
        expect(
          container.read(settingsProvider).value?.ambientMusicEnabled,
          isTrue,
        );
      },
    );
  });

  group('Fix 3 — atmosphere/sign selection honesty', () {
    test(
      'sign change while ambient enabled reports failure and stays coherent',
      () async {
        final sound = _ControllableSound()..signShouldFail = true;
        final container = await containerWith(sound);
        addTearDown(container.dispose);
        addTearDown(sound.dispose);

        final result = await container
            .read(settingsProvider.notifier)
            .saveSettings(
              const PersonalizationSettings(
                ambientMusicEnabled: true,
                atmosphereSign: ZodiacSignId.leo,
              ),
            );

        expect(result.ambientFailed, isTrue);
        // Coherence: audio could not actually start with the new sign, so
        // ambient music is not left claiming ON with silence playing.
        expect(result.settings.ambientMusicEnabled, isFalse);
        expect(sound.signCalls, contains(ZodiacSignId.leo));
      },
    );

    test('sign change while ambient disabled never fails', () async {
      final sound = _ControllableSound()..signShouldFail = true;
      final container = await containerWith(sound);
      addTearDown(container.dispose);
      addTearDown(sound.dispose);

      final result = await container
          .read(settingsProvider.notifier)
          .saveSettings(
            const PersonalizationSettings(
              ambientMusicEnabled: false,
              atmosphereSign: ZodiacSignId.leo,
            ),
          );

      // The fake always reports sign failure, but since ambient stays OFF
      // there was nothing to keep coherent, and the request itself already
      // matches the corrected value.
      expect(result.settings.ambientMusicEnabled, isFalse);
    });
  });

  group('Fix 4 — voice bind never crashes or silently disappears', () {
    test('a broken TTS engine bind is reported, not swallowed', () async {
      final sound = _ControllableSound();
      final container = await containerWith(sound, tts: _ThrowingTts());
      addTearDown(container.dispose);
      addTearDown(sound.dispose);

      // voiceRepliesEnabled is derived from orOutputMode by copyWith, so
      // the output mode is what actually drives it here.
      final result = await container
          .read(settingsProvider.notifier)
          .saveSettings(
            const PersonalizationSettings(orOutputMode: 'voice'),
          );

      // Must not throw out of saveSettings, and must say so honestly.
      expect(result.voiceFailed, isTrue);
      // Persistence still completes — a broken voice engine must never
      // block the rest of Settings from saving.
      expect(
        container.read(settingsProvider).value?.voiceRepliesEnabled,
        isTrue,
      );
    });

    test(
      'FOLLOW-UP 2A: a broken bind never lets the UI claim full success',
      () async {
        // Policy choice (Option B): voiceRepliesEnabled is a persisted
        // PREFERENCE, not a proof that the engine can speak right now —
        // that real-time capability is independently tracked by
        // OraclyTtsGate.unavailable at the moment OR actually tries to
        // speak. What this test proves is the other half of the honesty
        // requirement: the Settings layer must never silently report
        // total success when bind() actually failed.
        final sound = _ControllableSound();
        final container = await containerWith(sound, tts: _ThrowingTts());
        addTearDown(container.dispose);
        addTearDown(sound.dispose);

        final result = await container
            .read(settingsProvider.notifier)
            .saveSettings(const PersonalizationSettings(orOutputMode: 'voice'));

        // hasFailure folds voiceFailed in — SettingsReferenceScreen._save
        // uses exactly this flag to show ResilienceCopy.settingsAudioApplyFailed,
        // so a broken bind can never look like a silent full success.
        expect(result.hasFailure, isTrue);
      },
    );
  });
}
