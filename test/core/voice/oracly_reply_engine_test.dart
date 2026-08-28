/// Composite OR TTS: HQ proxy first, honest device fallback, interrupt.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/oracly_proxy_speech.dart';
import 'package:oracly_new/core/voice/oracly_reply_tts.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

import 'oracly_tts_test_doubles.dart';

final _audio = List<int>.filled(48, 7);
final _clip = <String, dynamic>{
  'audioBase64': base64Encode(_audio),
  'mimeType': 'audio/mpeg',
};

void main() {
  setUp(OraclyProxySpeech.resetCache);
  test('configured proxy is preferred over device TTS', () async {
    final device = MemTtsDevice();
    final sink = MemSpeechSink();
    final transport = MemTtsTransport(_clip);
    final engine = OraclyReplyTts(
      proxy: OraclyProxySpeech(transport),
      device: device,
      playback: sink,
    );
    await engine.speak('selam', personality: AiPersonality.gentle);
    expect(sink.played.single, _audio);
    expect(device.spoken, isEmpty);
    expect(engine.lastSpeakFailed, isFalse);
    expect(engine.isSpeaking, isTrue);
    expect(transport.lastRequest?.payload['voiceId'], 'warm');
    expect(transport.lastRequest?.payload['speechSpeed'], 'normal');
  });

  test('proxy failure falls back to device without claiming studio voice', () async {
    final device = MemTtsDevice();
    final sink = MemSpeechSink();
    final engine = OraclyReplyTts(
      proxy: OraclyProxySpeech(MemTtsTransport(null)),
      device: device,
      playback: sink,
    );
    await engine.speak('selam', personality: AiPersonality.mystical);
    expect(sink.played, isEmpty);
    expect(device.spoken, ['selam']);
    expect(engine.lastSpeakFailed, isTrue);
  });

  test('unconfigured proxy uses device as honest fallback', () async {
    final device = MemTtsDevice();
    final sink = MemSpeechSink();
    final engine = OraclyReplyTts(
      proxy: OraclyProxySpeech(null),
      device: device,
      playback: sink,
    );
    expect(await engine.isAvailable(), isTrue);
    await engine.speak('selam', personality: AiPersonality.gentle);
    expect(device.spoken, ['selam']);
    expect(sink.played, isEmpty);
    expect(engine.lastSpeakFailed, isFalse);
    expect(engine.isSpeaking, isTrue);
  });

  test('no proxy and no device stays silent', () async {
    final device = MemTtsDevice()..available = false;
    final engine = OraclyReplyTts(
      proxy: OraclyProxySpeech(null),
      device: device,
      playback: MemSpeechSink(),
    );
    expect(await engine.isAvailable(), isFalse);
    await engine.speak('selam', personality: AiPersonality.gentle);
    expect(device.spoken, isEmpty);
    expect(engine.lastSpeakFailed, isTrue);
    expect(engine.isSpeaking, isFalse);
  });

  test('stop discards late proxy audio', () async {
    final ready = Completer<void>();
    final sink = MemSpeechSink();
    final engine = OraclyReplyTts(
      proxy: OraclyProxySpeech(MemTtsTransport(_clip, gate: ready)),
      device: MemTtsDevice(),
      playback: sink,
    );
    final pending = engine.speak(
      'selam',
      personality: AiPersonality.poetic,
    );
    await Future<void>.delayed(Duration.zero);
    await engine.stop();
    ready.complete();
    await pending;
    expect(sink.played, isEmpty);
    expect(engine.isSpeaking, isFalse);
  });

  test('tiny audio never plays as fake speech', () async {
    final sink = MemSpeechSink();
    final engine = OraclyReplyTts(
      proxy: OraclyProxySpeech(
        MemTtsTransport({
          'audioBase64': base64Encode([1, 2, 3]),
          'mimeType': 'audio/mpeg',
        }),
      ),
      device: MemTtsDevice()..available = false,
      playback: sink,
    );
    await engine.speak('selam', personality: AiPersonality.gentle);
    expect(sink.played, isEmpty);
    expect(engine.lastSpeakFailed, isTrue);
  });
}
