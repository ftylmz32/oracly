/// OR chat output mode — text default; STT independent from TTS.

library;



import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/voice/oracly_tts_gate.dart';

import 'package:oracly_new/core/voice/oracly_tts_port.dart';

import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';

import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';

import 'package:oracly_new/features/companion/controllers/companion_voice_controller.dart';

import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';

import 'package:oracly_new/features/companion/services/companion_voice_input_port.dart';

import 'package:oracly_new/features/premium/models/personalization_models.dart';



class _HoldTts implements OraclyTtsPort {

  final spoken = <String>[];

  var stopCount = 0;

  var speaking = false;

  var available = true;



  @override

  void Function(bool isSpeaking)? onSpeakingChanged;



  @override

  bool get isSpeaking => speaking;



  @override

  bool get lastSpeakFailed => false;



  @override

  Future<bool> isAvailable() async => available;



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

    stopCount++;

    speaking = false;

    onSpeakingChanged?.call(false);

  }

}



CompanionOutputController _controller(_HoldTts tts) {
  var mode = OraclyTtsGate.voiceRepliesEnabled
      ? OrChatOutputMode.voice
      : OrChatOutputMode.text;
  return CompanionOutputController(
    persistMode: (next) async {
      mode = next;
      OraclyTtsGate.voiceRepliesEnabled = next.isVoice;
    },
    readMode: () => mode,
  );
}



void main() {

  TestWidgetsFlutterBinding.ensureInitialized();



  late _HoldTts tts;

  late CompanionOutputController output;



  setUp(() {

    tts = _HoldTts();

    OraclyTtsGate.bind(

      service: tts,

      enabled: false,

      style: AiPersonality.mystical,

      language: 'tr',

    );

    output = _controller(tts);

  });



  tearDown(() {

    output.dispose();

    OraclyTtsGate.engine = null;

    OraclyTtsGate.voiceRepliesEnabled = false;

    OraclyTtsGate.speaking.value = false;

    OraclyTtsGate.paused.value = false;

    OraclyTtsGate.unavailable.value = false;

  });



  test('default output mode is written text', () {

    expect(output.mode, OrChatOutputMode.text);

    expect(output.isVoice, isFalse);

  });



  test('YAZILI speakNow never calls TTS', () async {

    await output.speakNow('selam yanıtı yeterince uzun');

    expect(tts.spoken, isEmpty);

    expect(tts.stopCount, 0);

  });



  test('voice mode speaks a valid reply when voice replies are ON', () async {

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('  Merhaba  ');

    expect(tts.spoken, ['Merhaba']);

    expect(output.isSpeaking, isTrue);

  });



  test('YAZILI blocks speakChat even when global voice replies are OFF', () async {

    OraclyTtsGate.voiceRepliesEnabled = false;

    await OraclyTtsGate.speakChat('selam');

    expect(tts.spoken, isEmpty);

  });



  test('turning off voice replies silences speakIfVoice', () async {

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('selam');

    expect(tts.spoken, ['selam']);

    await output.setMode(OrChatOutputMode.text);

    tts.spoken.clear();

    await output.speakIfVoice('selam');

    expect(tts.spoken, isEmpty);

  });



  test('empty and error-like blank never speak', () async {

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('');

    await output.speakIfVoice('   ');

    await output.speakIfVoice(null);

    expect(tts.spoken, isEmpty);

  });



  test('switching to text and Durdur both stop speech', () async {

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('Konuşulan yanıt');

    expect(output.isSpeaking, isTrue);

    await output.setMode(OrChatOutputMode.text);

    expect(output.isSpeaking, isFalse);

    expect(tts.stopCount, greaterThan(0));

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('İkinci');

    final before = tts.stopCount;

    await output.stop();

    expect(tts.stopCount, before + 1);

    expect(output.isSpeaking, isFalse);

  });



  test('output mode follows voice replies gate after reload', () async {

    await output.setMode(OrChatOutputMode.voice);

    output.dispose();

    OraclyTtsGate.voiceRepliesEnabled = true;

    output = _controller(tts);

    expect(output.mode, OrChatOutputMode.voice);

  });



  test('SESLİ is honest immediately when the engine is unusable', () async {

    tts.available = false;

    await output.setMode(OrChatOutputMode.voice);

    expect(output.voiceUnavailable, isTrue);

    expect(tts.spoken, isEmpty);

  });



  test(

    'typed selam stays silent in YAZILI and speaks in SESLİ until stop',

    () async {

      await output.speakIfVoice('selam');

      expect(tts.spoken, isEmpty);

      await output.setMode(OrChatOutputMode.voice);

      await output.speakIfVoice('selam');

      expect(tts.spoken, ['selam']);

      await output.stop();

      expect(output.isSpeaking, isFalse);

      expect(tts.stopCount, greaterThan(0));

    },

  );



  test('STT session does not switch output mode', () async {

    await output.setMode(OrChatOutputMode.text);

    final voice = CompanionVoiceController(

      const UnavailableCompanionVoiceInput(),

    );

    addTearDown(voice.dispose);

    await voice.start(existingText: 'selam');

    expect(output.mode, OrChatOutputMode.text);

    expect(tts.spoken, isEmpty);

  });



  test('new message interrupts current speech', () async {

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('Birinci yanıt');

    expect(output.isSpeaking, isTrue);

    await output.onUserSend();

    expect(output.isSpeaking, isFalse);

    expect(tts.stopCount, greaterThan(0));

  });



  test('SESLİ stays honest when speech is unavailable', () async {

    tts.available = false;

    await output.setMode(OrChatOutputMode.voice);

    await output.speakIfVoice('selam');

    expect(tts.spoken, isEmpty);

    expect(output.voiceUnavailable, isTrue);

    expect(output.isSpeaking, isFalse);

  });

  test('pause resume stop and replay keep a clear playback state', () async {
    await output.setMode(OrChatOutputMode.voice);
    await output.speakIfVoice('Sakin bir yanıt');
    expect(output.isSpeaking, isTrue);
    expect(output.isPaused, isFalse);

    await output.pause();
    expect(output.isPaused, isTrue);
    expect(output.isSpeaking, isTrue);

    await output.resume();
    expect(output.isPaused, isFalse);

    await output.stop();
    expect(output.isSpeaking, isFalse);
    expect(output.isPaused, isFalse);
    expect(output.canReplay, isTrue);

    tts.spoken.clear();
    await output.replay();
    expect(tts.spoken, ['Sakin bir yanıt']);
    expect(output.isSpeaking, isTrue);
  });

  test('YAZILI never auto-speaks a new reply', () async {
    await output.setMode(OrChatOutputMode.text);
    await output.speakIfVoice('Bu yanıt sesli olmaz');
    expect(tts.spoken, isEmpty);
    expect(output.canReplay, isFalse);
  });
}


