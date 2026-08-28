/// Phase 5 — Atmospheric music gate (independent from SFX).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_atmosphere_palette.dart';
import 'package:oracly_new/core/audio/oracly_feedback_gate.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/audio/oracly_wav_synth.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SpySound extends OraclySoundService {
  var ambientSyncCalls = <bool>[];
  var atmosphereCalls = <ZodiacSignId>[];
  var stopCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncAmbientEnabled(bool enabled) async {
    ambientSyncCalls.add(enabled);
    await super.syncAmbientEnabled(enabled);
  }

  @override
  Future<void> setAtmosphere(ZodiacSignId sign) async {
    atmosphereCalls.add(sign);
    await super.setAtmosphere(sign);
  }

  @override
  Future<void> stopAmbient() async {
    stopCount++;
  }

  @override
  Future<void> refreshAmbient() async {}
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

  test('ambient volume token stays quiet', () {
    expect(OraclyAtmospherePalette.volume, lessThanOrEqualTo(0.15));
  });

  test('ambient OFF stops immediately via syncAmbientEnabled', () async {
    final spy = _SpySound();
    await spy.syncAmbientEnabled(true);
    expect(spy.ambientEnabled, isTrue);
    expect(spy.ambientSyncCalls, [true]);
    await spy.syncAmbientEnabled(false);
    expect(spy.ambientEnabled, isFalse);
    expect(spy.ambientSyncCalls, [true, false]);
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

    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(
            ambientMusicEnabled: true,
            atmosphereSign: ZodiacSignId.leo,
          ),
        );

    expect(spy.ambientSyncCalls, contains(true));
    expect(spy.atmosphereCalls, contains(ZodiacSignId.leo));

    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(ambientMusicEnabled: false),
        );
    expect(spy.ambientSyncCalls.last, isFalse);
  });

  test('cold start restores persisted ambient ON without opening Settings',
      () async {
    SharedPreferences.setMockInitialValues({
      'settings_ambient_music': true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final spy = _SpySound();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclySoundServiceProvider.overrideWithValue(spy),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    expect(spy.ambientSyncCalls, contains(true));
  });
}
