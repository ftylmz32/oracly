/// Test doubles for composite OR TTS.
library;

import 'dart:async';

import 'package:oracly_new/core/voice/oracly_speech_player.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

class MemTtsTransport implements AiTransport {
  MemTtsTransport(this.data, {this.gate});

  final Map<String, dynamic>? data;
  final Completer<void>? gate;
  AiProxyRequest? lastRequest;

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(AiProxyRequest request) async {
    lastRequest = request;
    await gate?.future;
    final body = data;
    if (body == null) return AiOutcome.failure(AiFailure.providerError());
    return AiOutcome.success(body);
  }
}

class MemTtsDevice implements OraclyTtsPort {
  final spoken = <String>[];
  var available = true;
  var speaking = false;

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
    spoken.add(text);
    speaking = true;
  }

  @override
  Future<void> stop() async {
    speaking = false;
  }
}

class MemSpeechSink implements OraclySpeechSink {
  final played = <List<int>>[];

  @override
  void Function()? onComplete;

  @override
  void Function()? onInterrupted;

  @override
  Future<void> play(List<int> bytes, {String mimeType = 'audio/mpeg'}) async {
    played.add(bytes);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}
}
