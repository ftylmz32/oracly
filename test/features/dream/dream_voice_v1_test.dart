/// Dream Sesli Anlat V1 — permission, STT honesty, review, analysis handoff.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/dream/controllers/dream_voice_controller.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/services/dream_voice_input_port.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_failure.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_permission.dart';
import 'package:oracly_new/features/dream/voice/dream_voice_phase.dart';

void main() {
  // The controller reads WidgetsBinding for lifecycle observation.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unavailable port is honest and never invents a transcript', () async {
    const port = UnavailableDreamVoiceInput();
    expect(port.isAvailable, isFalse);
    expect(await port.isSpeechAvailable(), isFalse);
    expect(await port.requestPermission(), DreamVoicePermission.unavailable);
    DreamVoiceFailure? failure;
    await port.startListening(
      onResult: (text, isFinal) => fail('must not fabricate text'),
      onError: (error) => failure = error,
    );
    expect(failure?.kind, DreamVoiceFailureKind.speechUnavailable);
    expect(failure?.userMessage, DreamCopy.voiceSpeechUnavailable);
  });

  test('voice failure copy is Turkish and never a fake transcript', () {
    expect(
      DreamVoiceFailure.permissionDenied().userMessage,
      DreamCopy.voicePermissionDenied,
    );
    expect(
      DreamVoiceFailure.permissionPermanentlyDenied().userMessage,
      DreamCopy.voicePermissionPermanent,
    );
    expect(
      DreamVoiceFailure.emptyTranscription().userMessage,
      DreamCopy.voiceEmpty,
    );
    expect(DreamVoiceFailure.network().userMessage, ResilienceCopy.offline);
    expect(DreamVoiceFailure.timeout().userMessage, ResilienceCopy.slowResponse);
    expect(DreamCopy.voiceListening, 'Dinliyorum...');
    expect(DreamCopy.voiceStop, 'Durdur');
    expect(DreamCopy.voiceReviewTitle, 'Rüyanı kontrol et');
    expect(DreamCopy.voiceListenAgain, 'Tekrar Dinle');
    expect(DreamCopy.beginAnalysis, 'RÜYAMI YORUMLA');
  });

  test('permission denied stays on error without fake text', () async {
    final voice = DreamVoiceController(
      _FakeVoice(permission: DreamVoicePermission.denied),
    );
    await voice.start();
    expect(voice.phase, DreamVoicePhase.error);
    expect(voice.errorMessage, DreamCopy.voicePermissionDenied);
    expect(voice.transcript, isEmpty);
  });

  test('speech unavailable does not pretend recognition worked', () async {
    final voice = DreamVoiceController(_FakeVoice(available: false));
    await voice.start();
    expect(voice.phase, DreamVoicePhase.error);
    expect(voice.errorMessage, DreamCopy.voiceSpeechUnavailable);
  });

  test('stop yields editable transcript then analysis can use edits', () async {
    final port = _LiveFake();
    final voice = DreamVoiceController(port);
    await voice.start();
    expect(voice.phase, DreamVoicePhase.recording);
    expect(voice.transcript, 'kısmi');
    await voice.stop();
    expect(voice.phase, DreamVoicePhase.transcribed);
    expect(voice.transcript, 'Rüyamda uzun bir yol vardı.');
    voice.editTranscript('Rüyamda uzun bir yol vardı ve annem de oradaydı.');
    expect(voice.transcript, contains('annem'));
  });

  test('empty transcription is an error, not a fake dream', () async {
    final voice = DreamVoiceController(_LiveFake(finalWords: ''));
    await voice.start();
    await voice.stop();
    expect(voice.phase, DreamVoicePhase.error);
    expect(voice.errorMessage, DreamCopy.voiceEmpty);
  });

  test('rapid start taps do not open a second recording', () async {
    final port = _LiveFake();
    final voice = DreamVoiceController(port);
    await voice.start();
    await voice.start();
    await voice.start();
    expect(port.startCount, 1);
    expect(voice.phase, DreamVoicePhase.recording);
  });

  test('listen again after review starts a new session', () async {
    final port = _LiveFake();
    final voice = DreamVoiceController(port);
    await voice.start();
    await voice.stop();
    expect(voice.phase, DreamVoicePhase.transcribed);
    await voice.listenAgain();
    expect(voice.phase, DreamVoicePhase.recording);
    expect(port.startCount, 2);
  });
}

class _FakeVoice implements DreamVoiceInputPort {
  _FakeVoice({
    this.available = true,
    this.permission = DreamVoicePermission.granted,
  });

  final bool available;
  final DreamVoicePermission permission;

  @override
  bool get isAvailable => available;

  @override
  Future<bool> isSpeechAvailable() async => available;

  @override
  Future<DreamVoicePermission> requestPermission() async => permission;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    fail('startListening should not run for this fake');
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
}

class _LiveFake implements DreamVoiceInputPort {
  _LiveFake({this.finalWords = 'Rüyamda uzun bir yol vardı.'});

  final String finalWords;
  var startCount = 0;
  void Function(String text, bool isFinal)? _onResult;
  VoidCallback? _onEnded;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> isSpeechAvailable() async => true;

  @override
  Future<DreamVoicePermission> requestPermission() async =>
      DreamVoicePermission.granted;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    startCount += 1;
    _onResult = onResult;
    _onEnded = onListeningEnded;
    if (finalWords.isNotEmpty) onResult('kısmi', false);
  }

  @override
  Future<void> stopListening() async {
    _onResult?.call(finalWords, true);
    _onEnded?.call();
  }

  @override
  Future<void> cancelListening() async {}
}
