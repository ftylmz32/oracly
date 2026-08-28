/// Phase 4 — Sound + haptic gate runtime (no Music / TTS).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_feedback_gate.dart';
import 'package:oracly_new/core/audio/oracly_sound_chamber.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/audio/oracly_wav_synth.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CountingSoundService extends OraclySoundService {
  final plays = <OraclySoundCue>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play(OraclySoundCue cue) async {
    plays.add(cue);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    OraclyFeedbackGate.sound = null;
    OraclyFeedbackGate.soundEnabled = true;
    OraclyFeedbackGate.hapticEnabled = true;
  });

  test('softTap / selection / reveal synth bytes are non-empty', () {
    expect(OraclyWavSynth.paperRustle().length, greaterThan(44));
    expect(OraclyWavSynth.selectionTick().length, greaterThan(44));
    expect(
      OraclyWavSynth.sweep(fromHz: 180, toHz: 320, durationMs: 120).length,
      greaterThan(44),
    );
    expect(
      OraclyWavSynth.chime(frequencies: const [392, 523], durationMs: 200)
          .length,
      greaterThan(44),
    );
  });

  test('sound OFF blocks all purposeful cues at the gate', () {
    final service = _CountingSoundService();
    OraclyFeedbackGate.bind(
      service: service,
      haptics: true,
      sounds: false,
    );

    OraclyFeedbackGate.softTap();
    OraclyFeedbackGate.selection();
    OraclyFeedbackGate.cardMove();
    OraclyFeedbackGate.cardReveal();
    OraclyFeedbackGate.revealBloom();
    OraclyFeedbackGate.specialReveal();
    OraclyFeedbackGate.successfulAnalysis();

    expect(service.plays, isEmpty);
  });

  test('sound ON maps intended cues; buttonTap aliases softTap', () {
    final service = _CountingSoundService();
    OraclyFeedbackGate.bind(
      service: service,
      haptics: true,
      sounds: true,
    );

    OraclyFeedbackGate.playCue(OraclySoundCue.buttonTap);
    OraclyFeedbackGate.selection();
    OraclyFeedbackGate.cardMove();
    OraclyFeedbackGate.cardReveal();
    OraclyFeedbackGate.revealBloom();
    OraclyFeedbackGate.specialReveal();
    OraclyFeedbackGate.successfulAnalysis();

    expect(service.plays, [
      OraclySoundCue.softTap,
      OraclySoundCue.selection,
      OraclySoundCue.cardSlide,
      OraclySoundCue.cardFlip,
      OraclySoundCue.revealTone,
      OraclySoundCue.magicalReveal,
      OraclySoundCue.journeyComplete,
    ]);
  });

  test('haptic OFF prevents OraclyTouchFeedback calls from throwing', () {
    OraclyFeedbackGate.hapticEnabled = false;
    OraclyTouchFeedback.acknowledge();
    OraclyTouchFeedback.selection();
    OraclyTouchFeedback.reveal();
    OraclyFeedbackGate.hapticEnabled = true;
  });

  test('sound and haptic prefs persist', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = LocalSettingsRepository(storage);

    await repo.save(
      const PersonalizationSettings(
        soundEnabled: false,
        hapticEnabled: false,
      ),
    );
    final loaded = await repo.load();
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.hapticEnabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_sound'), isFalse);
    expect(prefs.getBool('settings_haptic'), isFalse);
  });

  test('settingsNotifier saveSettings binds the live gate', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final service = _CountingSoundService();

    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclySoundServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    expect(OraclyFeedbackGate.soundEnabled, isTrue);
    expect(OraclyFeedbackGate.hapticEnabled, isTrue);

    await container.read(settingsProvider.notifier).saveSettings(
          const PersonalizationSettings(
            soundEnabled: false,
            hapticEnabled: false,
          ),
        );

    expect(OraclyFeedbackGate.soundEnabled, isFalse);
    expect(OraclyFeedbackGate.hapticEnabled, isFalse);
    expect(OraclyFeedbackGate.sound, same(service));

    OraclyFeedbackGate.softTap();
    OraclyFeedbackGate.selection();
    expect(service.plays, isEmpty);

    OraclyTouchFeedback.acknowledge();
    OraclyTouchFeedback.selection();
  });
}
