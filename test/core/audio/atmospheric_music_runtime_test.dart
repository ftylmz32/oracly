/// Phase 5 — Atmospheric music gate (independent from SFX).
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_ambient_audio_context.dart';
import 'package:oracly_new/core/audio/oracly_ambient_bed.dart';
import 'package:oracly_new/core/audio/oracly_atmosphere_palette.dart';
import 'package:oracly_new/core/audio/oracly_feedback_gate.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/audio/oracly_wav_synth.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/shared/navigation/oracly_shell_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpySound extends OraclySoundService {
  var ambientSyncCalls = <bool>[];
  var atmosphereCalls = <ZodiacSignId>[];
  var stopCount = 0;
  var refreshCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<OraclyApplyOutcome> syncAmbientEnabled(bool enabled) async {
    ambientSyncCalls.add(enabled);
    return super.syncAmbientEnabled(enabled);
  }

  @override
  Future<OraclyApplyOutcome> setAtmosphere(ZodiacSignId sign) async {
    atmosphereCalls.add(sign);
    return super.setAtmosphere(sign);
  }

  @override
  Future<OraclyApplyOutcome> stopAmbient() async {
    stopCount++;
    return super.stopAmbient();
  }

  @override
  Future<OraclyApplyOutcome> refreshAmbient() async {
    refreshCount++;
    return super.refreshAmbient();
  }
}

class _CountingSound extends OraclySoundService {
  final atmosphereCalls = <ZodiacSignId>[];
  final ambientSyncCalls = <bool>[];

  @override
  Future<OraclyApplyOutcome> setAtmosphere(ZodiacSignId sign) async {
    atmosphereCalls.add(sign);
    return OraclyApplyOutcome.success;
  }

  @override
  Future<OraclyApplyOutcome> syncAmbientEnabled(bool enabled) async {
    ambientSyncCalls.add(enabled);
    return OraclyApplyOutcome.success;
  }

  @override
  Future<void> dispose() async {}
}

class _ShellPersonalizationProbe extends ConsumerStatefulWidget {
  const _ShellPersonalizationProbe();

  @override
  ConsumerState<_ShellPersonalizationProbe> createState() =>
      _ShellPersonalizationProbeState();
}

class _ShellPersonalizationProbeState
    extends ConsumerState<_ShellPersonalizationProbe> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => OraclyShellRuntime.applyPersonalization(ref, syncAudio: false),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

int _pcmPeakAbs(Uint8List wav) {
  var maxAbs = 0;
  for (var i = 44; i + 1 < wav.length; i += 2) {
    final lo = wav[i];
    final hi = wav[i + 1];
    var sample = lo | (hi << 8);
    if (sample >= 0x8000) sample -= 0x10000;
    final abs = sample.abs();
    if (abs > maxAbs) maxAbs = abs;
  }
  return maxAbs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    OraclyFeedbackGate.sound = null;
    OraclyFeedbackGate.soundEnabled = true;
  });

  test('ambient music defaults OFF in settings', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final loaded = await LocalSettingsRepository(storage).load();
    expect(loaded.ambientMusicEnabled, isFalse);
    expect(loaded.atmosphereSign, ZodiacSignId.cancer);
  });

  test('ambient music + atmosphere persist', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = LocalSettingsRepository(storage);
    await repo.save(
      const PersonalizationSettings(
        ambientMusicEnabled: true,
        atmosphereSign: ZodiacSignId.scorpio,
      ),
    );
    final loaded = await repo.load();
    expect(loaded.ambientMusicEnabled, isTrue);
    expect(loaded.atmosphereSign, ZodiacSignId.scorpio);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_ambient_music'), isTrue);
    expect(prefs.getString('settings_atmosphere_sign'), 'scorpio');
  });

  test('SFX OFF does not stop ambient via gate bind', () {
    final spy = _SpySound();
    OraclyFeedbackGate.bind(service: spy, haptics: true, sounds: false);
    expect(spy.ambientSyncCalls, isEmpty);
    expect(OraclyFeedbackGate.soundEnabled, isFalse);
  });

  test('all twelve burç atmosphere loops synthesize', () {
    for (final sign in ZodiacSignId.values) {
      final bytes = OraclyWavSynth.zodiacAtmosphere(sign);
      expect(bytes.length, greaterThan(44), reason: sign.labelTr);
      expect(OraclyAtmospherePalette.frequencies(sign), isNotEmpty);
    }
  });

  test('ambient gain stays soft but device-audible', () {
    expect(OraclyAtmospherePalette.volume, greaterThan(0.2));
    expect(OraclyAtmospherePalette.volume, lessThanOrEqualTo(0.4));
    expect(OraclyAtmospherePalette.bedVolume, greaterThan(0.3));
    expect(OraclyAtmospherePalette.bedVolume, lessThanOrEqualTo(0.55));
  });

  test('zodiac atmosphere PCM peak is audibly scaled', () {
    final peak = _pcmPeakAbs(OraclyWavSynth.zodiacAtmosphere(ZodiacSignId.leo));
    // ~0.12 of full-scale minimum — was ~0.028 before the gate fix.
    expect(peak, greaterThan(3500));
    expect(peak, lessThan(22000));
  });

  test('distinct signs produce distinct frequency palettes', () {
    expect(
      OraclyAtmospherePalette.frequencies(ZodiacSignId.aries),
      isNot(OraclyAtmospherePalette.frequencies(ZodiacSignId.pisces)),
    );
  });

  test('ambient OFF stops immediately via syncAmbientEnabled', () async {
    final spy = _SpySound();
    addTearDown(spy.dispose);
    await spy.syncAmbientEnabled(true);
    expect(spy.ambientEnabled, isTrue);
    expect(spy.ambientSyncCalls, [true]);
    await spy.syncAmbientEnabled(false);
    expect(spy.ambientEnabled, isFalse);
    expect(spy.ambientSyncCalls, [true, false]);
  });

  test('selecting atmosphere updates canonical sign state', () async {
    final bed = OraclyAmbientBed();
    addTearDown(bed.dispose);
    expect(bed.sign, ZodiacSignId.cancer);
    await bed.setSign(ZodiacSignId.libra);
    expect(bed.sign, ZodiacSignId.libra);
    expect(bed.enabled, isFalse);
  });

  test('switching atmosphere while enabled replaces sign on service', () async {
    final service = OraclySoundService();
    addTearDown(service.dispose);
    await service.setAtmosphere(ZodiacSignId.aries);
    await service.syncAmbientEnabled(true);
    expect(service.atmosphere, ZodiacSignId.aries);
    expect(service.ambientEnabled, isTrue);
    await service.setAtmosphere(ZodiacSignId.scorpio);
    expect(service.atmosphere, ZodiacSignId.scorpio);
    await service.syncAmbientEnabled(false);
    expect(service.ambientEnabled, isFalse);
  });

  test('atmosphere change while OFF does not enable playback', () async {
    final service = OraclySoundService();
    addTearDown(service.dispose);
    await service.setAtmosphere(ZodiacSignId.leo);
    expect(service.ambientEnabled, isFalse);
    expect(service.atmosphere, ZodiacSignId.leo);
  });

  test('production provider is real OraclySoundService not a no-op mock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sound = container.read(oraclySoundServiceProvider);
    expect(sound, isA<OraclySoundService>());
    expect(sound.runtimeType, OraclySoundService);
  });

  test('settingsNotifier awaits ambient sync on save', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final spy = _SpySound();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclySoundServiceProvider.overrideWithValue(spy),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(spy.dispose);

    await container.read(settingsProvider.future);
    await container
        .read(settingsProvider.notifier)
        .saveSettings(
          const PersonalizationSettings(
            ambientMusicEnabled: true,
            atmosphereSign: ZodiacSignId.leo,
          ),
        );

    expect(spy.ambientSyncCalls, contains(true));
    expect(spy.atmosphereCalls, contains(ZodiacSignId.leo));

    await container
        .read(settingsProvider.notifier)
        .saveSettings(
          const PersonalizationSettings(ambientMusicEnabled: false),
        );
    expect(spy.ambientSyncCalls.last, isFalse);
  });

  test(
    'cold start restores persisted ambient ON without opening Settings',
    () async {
      SharedPreferences.setMockInitialValues({'settings_ambient_music': true});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final spy = _SpySound();
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclySoundServiceProvider.overrideWithValue(spy),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(spy.dispose);

      await container.read(settingsProvider.future);
      expect(spy.ambientSyncCalls, contains(true));
    },
  );

  testWidgets('shell personalization does not duplicate settings audio sync', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'settings_ambient_music': true,
      'settings_atmosphere_sign': 'leo',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final spy = _CountingSound();
    addTearDown(spy.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclySoundServiceProvider.overrideWithValue(spy),
        ],
        child: const MaterialApp(home: _ShellPersonalizationProbe()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(spy.atmosphereCalls, [ZodiacSignId.leo]);
    expect(spy.ambientSyncCalls, [true]);
  });

  test('epoch bump on disable prevents stale refresh races', () async {
    final bed = OraclyAmbientBed();
    addTearDown(bed.dispose);
    await bed.setEnabled(true);
    expect(bed.enabled, isTrue);
    await bed.setEnabled(false);
    expect(bed.enabled, isFalse);
    // A late refresh with an old epoch must not re-enable.
    await bed.refresh(epoch: 0);
    expect(bed.enabled, isFalse);
  });

  group('RELIABILITY BATCH 2A — Fix 1/3: real outcome, never swallowed', () {
    test(
      'ensureReady reports failure honestly when the platform plugin is unavailable',
      () async {
        final bed = OraclyAmbientBed();
        addTearDown(bed.dispose);
        // No audioplayers platform channel registered in this sandbox —
        // a real, not fabricated, failure.
        final ready = await bed.ensureReady();
        expect(ready, isFalse);
      },
    );

    test(
      'setEnabled(true) returns a real failure outcome instead of silently succeeding',
      () async {
        final bed = OraclyAmbientBed();
        addTearDown(bed.dispose);
        final outcome = await bed.setEnabled(true);
        expect(outcome, OraclyApplyOutcome.failure);
      },
    );

    test(
      'setEnabled(false) succeeds even when nothing was ever playing',
      () async {
        final bed = OraclyAmbientBed();
        addTearDown(bed.dispose);
        final outcome = await bed.setEnabled(false);
        expect(outcome, OraclyApplyOutcome.success);
      },
    );

    test(
      'setSign while disabled never attempts playback and always succeeds',
      () async {
        final bed = OraclyAmbientBed();
        addTearDown(bed.dispose);
        final outcome = await bed.setSign(ZodiacSignId.aries);
        expect(outcome, OraclyApplyOutcome.success);
        expect(bed.sign, ZodiacSignId.aries);
      },
    );
  });

  group('FOLLOW-UP 2A — Fix 1: a stop failure never claims OFF', () {
    test(
      'a stop failure keeps the bed effectively enabled, never a false OFF',
      () async {
        final bed = _StopFailsBed();
        addTearDown(bed.dispose);
        await bed.setEnabled(true);
        expect(bed.enabled, isTrue);

        final outcome = await bed.setEnabled(false);

        expect(outcome, OraclyApplyOutcome.failure);
        // Stop was never proven to have worked — must not claim OFF while
        // playback may still be audible.
        expect(bed.enabled, isTrue);
      },
    );

    test('a successful stop still commits to disabled as before', () async {
      final bed = OraclyAmbientBed();
      addTearDown(bed.dispose);
      await bed.setEnabled(true);
      final outcome = await bed.setEnabled(false);
      // No plugin registered, so nothing was ever actually playing —
      // stop() on a null player is a trivial, real success.
      expect(outcome, OraclyApplyOutcome.success);
      expect(bed.enabled, isFalse);
    });
  });

  group('real-device regression: ambient AudioContext construction', () {
    test(
      'oraclyAmbientAudioContext never throws (real-device-confirmed '
      'AudioContextIOS assertion: mixWithOthers may not be set explicitly '
      'alongside the ambient category, which already implies it)',
      () {
        // Before the fix this threw a Dart assertion error even on Android,
        // because AudioContext(android:, iOS:) unconditionally constructs
        // the iOS sub-config regardless of the runtime platform — masked in
        // the `ensureReady`-level tests above because a missing platform
        // channel produces the same "failure" outcome as this assertion did.
        expect(oraclyAmbientAudioContext, returnsNormally);
      },
    );
  });
}

class _StopFailsBed extends OraclyAmbientBed {
  @override
  Future<OraclyApplyOutcome> stop() async => OraclyApplyOutcome.failure;
}
