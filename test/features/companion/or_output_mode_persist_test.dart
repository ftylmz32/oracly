/// OR output mode persists; never auto-starts mic or speech.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_settings_repository.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_voice_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_voice_turn_controller.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/services/companion_voice_input_port.dart';
import 'package:oracly_new/features/companion/voice/companion_speech_result.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_failure.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_permission.dart';
import 'package:oracly_new/features/companion/voice/or_voice_turn_phase.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SilentStt implements CompanionVoiceInputPort {
  var startCount = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<bool> isSpeechAvailable() async => true;
  @override
  Future<CompanionVoicePermission> requestPermission() async =>
      CompanionVoicePermission.granted;
  @override
  Future<void> startListening({
    required void Function(CompanionSpeechResult result) onResult,
    required void Function(CompanionVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    startCount++;
  }
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> cancelListening() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('three modes persist safely across reload', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = LocalSettingsRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    for (final mode in OrChatOutputMode.values) {
      await repo.save(PersonalizationSettings(orOutputMode: mode.wire));
      final loaded = await repo.load();
      expect(loaded.orOutputMode, mode.wire);
      expect(loaded.voiceRepliesEnabled, mode.isVoice);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(OrChatOutputMode.storageKey), mode.wire);
    }
  });

  test('legacy voice bool migrates to voice replies, not conversation', () async {
    SharedPreferences.setMockInitialValues({
      'settings_voice_replies': true,
    });
    final repo = LocalSettingsRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final loaded = await repo.load();
    expect(loaded.orOutputMode, 'voice');
    expect(loaded.voiceRepliesEnabled, isTrue);
  });

  test('choosing conversation does not open the microphone', () async {
    var mode = OrChatOutputMode.text;
    final output = CompanionOutputController(
      persistMode: (next) async => mode = next,
      readMode: () => mode,
    );
    final stt = _SilentStt();
    final voice = CompanionVoiceController(stt);
    final turn = CompanionVoiceTurnController(voice: voice, output: output);
    await output.setMode(OrChatOutputMode.conversation);
    turn.setActive(true);
    expect(output.mode, OrChatOutputMode.conversation);
    expect(turn.phase, OrVoiceTurnPhase.ready);
    expect(stt.startCount, 0);
    expect(OraclyTtsGate.speaking.value, isFalse);
    turn.dispose();
    voice.dispose();
    output.dispose();
  });
}

