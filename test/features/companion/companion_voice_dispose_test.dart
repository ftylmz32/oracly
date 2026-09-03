/// Disposed CompanionVoiceTurnController must ignore later callbacks.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('disposed turn ignores mic and setActive without throwing', () async {
    OraclyTtsGate.bind(
      service: _SilentTts(),
      enabled: true,
      style: AiPersonality.mystical,
      language: 'tr',
    );
    addTearDown(() => OraclyTtsGate.engine = null);

    final output = CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.conversation,
    );
    final voice = CompanionVoiceController(_SilentStt());
    final turn = CompanionVoiceTurnController(voice: voice, output: output);
    turn.setActive(true);
    expect(turn.isActive, isTrue);

    turn.dispose();
    expect(turn.isDisposed, isTrue);

    turn.setActive(true);
    turn.bindSender((_) async {});
    await turn.onMicTap();
    await turn.cancel();
    await turn.handleExternalInterrupt();

    expect(turn.isActive, isFalse);
    expect(turn.phase, OrVoiceTurnPhase.ready);

    voice.dispose();
    output.dispose();
  });
}

class _SilentTts implements OraclyTtsPort {
  @override
  void Function(bool isSpeaking)? onSpeakingChanged;
  @override
  bool get isSpeaking => false;
  @override
  bool get lastSpeakFailed => false;
  @override
  Future<bool> isAvailable() async => true;
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

class _SilentStt implements CompanionVoiceInputPort {
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
  }) async {}
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> cancelListening() async {}
}
