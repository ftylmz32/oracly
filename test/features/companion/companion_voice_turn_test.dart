/// Voice conversation turns — clear phases, no mic auto-loop.
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

class _HoldTts implements OraclyTtsPort {
  final spoken = <String>[];
  var speaking = false;
  @override
  void Function(bool isSpeaking)? onSpeakingChanged;
  @override
  bool get isSpeaking => speaking;
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
  }) async {
    speaking = true;
    onSpeakingChanged?.call(true);
    spoken.add(text.trim());
  }

  @override
  Future<void> stop() async {
    speaking = false;
    onSpeakingChanged?.call(false);
  }
}

class _LiveStt implements CompanionVoiceInputPort {
  var startCount = 0;
  double? finalConfidence;
  void Function(CompanionSpeechResult result)? _onResult;
  VoidCallback? _onEnded;
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
    startCount += 1;
    _onResult = onResult;
    _onEnded = onListeningEnded;
    onResult(const CompanionSpeechResult(text: 'Merhaba OR', isFinal: false));
  }

  @override
  Future<void> stopListening() async {
    final onResult = _onResult;
    final onEnded = _onEnded;
    _onResult = null;
    _onEnded = null;
    onResult?.call(CompanionSpeechResult(
      text: 'Merhaba OR',
      isFinal: true,
      confidence: finalConfidence,
    ));
    onEnded?.call();
  }

  @override
  Future<void> cancelListening() async {
    _onResult = null;
    _onEnded = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _HoldTts tts;
  late CompanionOutputController output;
  late CompanionVoiceController voice;
  late _LiveStt stt;
  late List<String> sent;
  late CompanionVoiceTurnController turn;

  setUp(() async {
    tts = _HoldTts();
    OraclyTtsGate.bind(
      service: tts,
      enabled: true,
      style: AiPersonality.mystical,
      language: 'tr',
    );
    var mode = OrChatOutputMode.text;
    output = CompanionOutputController(
      persistMode: (next) async {
        mode = next;
        OraclyTtsGate.voiceRepliesEnabled = next.isVoice;
      },
      readMode: () => mode,
    );
    await output.setMode(OrChatOutputMode.conversation);
    stt = _LiveStt();
    voice = CompanionVoiceController(stt);
    sent = <String>[];
    turn = CompanionVoiceTurnController(voice: voice, output: output);
    turn.setActive(true);
    turn.bindSender((text) async {
      sent.add(text);
      await output.speakIfVoice('Sakin bir yanit');
    });
  });

  tearDown(() {
    turn.dispose();
    voice.dispose();
    output.dispose();
    OraclyTtsGate.engine = null;
    OraclyTtsGate.voiceRepliesEnabled = false;
    OraclyTtsGate.speaking.value = false;
    OraclyTtsGate.paused.value = false;
  });

  test('ready â†’ listen â†’ think â†’ speak â†’ ready, never auto-reopens mic', () async {
    expect(turn.phase, OrVoiceTurnPhase.ready);
    await turn.onMicTap();
    expect(turn.phase, OrVoiceTurnPhase.listening);
    expect(stt.startCount, 1);

    await turn.onMicTap();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(sent, ['Merhaba OR']);
    expect(turn.phase, OrVoiceTurnPhase.speaking);
    expect(stt.startCount, 1);

    await tts.stop();
    OraclyTtsGate.speaking.value = false;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(turn.phase, OrVoiceTurnPhase.ready);
    expect(stt.startCount, 1);
  });

  test('leaving conversation does not leave the mic armed', () async {
    await turn.onMicTap();
    expect(turn.phase, OrVoiceTurnPhase.listening);
    turn.setActive(false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(turn.isActive, isFalse);
    expect(turn.phase, OrVoiceTurnPhase.ready);
    expect(voice.isActive, isFalse);
  });

  test('output conversation mode enables voice replies without loops', () async {
    expect(output.isConversation, isTrue);
    expect(output.isVoice, isTrue);
    await output.setMode(OrChatOutputMode.text);
    expect(output.isConversation, isFalse);
    expect(tts.spoken, isEmpty);
  });

  test('low confidence holds for edit/retry and does not auto-send', () async {
    stt.finalConfidence = 0.3;
    await turn.onMicTap();
    await Future<void>.delayed(Duration.zero);
    await voice.stop();
    await Future<void>.delayed(Duration.zero);
    expect(sent, isEmpty);
    expect(voice.needsReview, isTrue);
    expect(voice.composerDraft, 'Merhaba OR');
    expect(turn.phase, OrVoiceTurnPhase.ready);
  });

}

