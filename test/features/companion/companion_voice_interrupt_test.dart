/// Voice interruption — no stuck listen/playback, no repeated replies.
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
  var stopCount = 0;
  var _gen = 0;
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
    final id = ++_gen;
    speaking = true;
    onSpeakingChanged?.call(true);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (id != _gen) return;
    spoken.add(text.trim());
  }

  @override
  Future<void> stop() async {
    _gen++;
    stopCount++;
    speaking = false;
    onSpeakingChanged?.call(false);
  }
}

class _LiveStt implements CompanionVoiceInputPort {
  var startCount = 0;
  var cancelCount = 0;
  void Function(CompanionSpeechResult result)? _onResult;
  void Function(CompanionVoiceFailure)? _onError;
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
    startCount++;
    _onResult = onResult;
    _onError = onError;
    _onEnded = onListeningEnded;
    onResult(const CompanionSpeechResult(text: 'kismi', isFinal: false));
  }

  @override
  Future<void> stopListening() async {
    final onResult = _onResult;
    final onEnded = _onEnded;
    _onResult = null;
    _onEnded = null;
    onResult?.call(const CompanionSpeechResult(text: 'Tamam', isFinal: true));
    onEnded?.call();
  }

  @override
  Future<void> cancelListening() async {
    cancelCount++;
    _onResult = null;
    _onEnded = null;
  }

  void revokePermission() {
    _onError?.call(CompanionVoiceFailure.permissionDenied());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _HoldTts tts;
  late CompanionOutputController output;
  late CompanionVoiceController voice;
  late _LiveStt stt;
  late CompanionVoiceTurnController turn;
  late List<String> sent;

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
      persistMode: (m) async {
        mode = m;
        OraclyTtsGate.voiceRepliesEnabled = m.isVoice;
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
      await output.speakIfVoice('Yanit $text');
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

  test('user barge-in stops playback and starts a fresh listen', () async {
    await turn.onMicTap();
    await turn.onMicTap();
    await Future<void>.delayed(const Duration(milliseconds: 520));
    expect(turn.phase, OrVoiceTurnPhase.speaking);
    final before = stt.startCount;
    await turn.onMicTap();
    expect(tts.speaking, isFalse);
    expect(OraclyTtsGate.speaking.value, isFalse);
    expect(OraclyTtsGate.paused.value, isFalse);
    expect(turn.phase, OrVoiceTurnPhase.listening);
    expect(stt.startCount, before + 1);
  });

  test('external interrupt clears listen and playback', () async {
    await turn.onMicTap();
    expect(turn.phase, OrVoiceTurnPhase.listening);
    await output.speakNow('Calisiyor');
    expect(tts.speaking || tts.spoken.isNotEmpty, isTrue);
    await turn.handleExternalInterrupt();
    expect(turn.phase, OrVoiceTurnPhase.ready);
    expect(voice.isActive, isFalse);
    expect(tts.speaking, isFalse);
    expect(OraclyTtsGate.paused.value, isFalse);
  });

  test('interrupt drops in-flight speak so replies are not repeated', () async {
    final pending = output.speakIfVoice('Birinci');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await output.interrupt();
    await pending;
    expect(tts.spoken, isNot(contains('Birinci')));
    expect(tts.speaking, isFalse);
    await output.speakIfVoice('Ikinci');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(tts.spoken, contains('Ikinci'));
  });

  test('permission revoked leaves ready, not stuck listening', () async {
    await turn.onMicTap();
    expect(turn.phase, OrVoiceTurnPhase.listening);
    stt.revokePermission();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(voice.isActive, isFalse);
    expect(turn.phase, OrVoiceTurnPhase.ready);
  });
}

