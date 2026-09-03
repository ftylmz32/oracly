/// OR Rehberi voice V1 — permission, STT honesty, composer draft, no auto-send.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/companion/controllers/companion_voice_controller.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_voice_listener.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/companion_voice_input_port.dart';
import 'package:oracly_new/features/companion/voice/companion_speech_result.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_failure.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_permission.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('idle starts requesting then listening', () async {
    final voice = CompanionVoiceController(_LiveFake());
    expect(voice.phase, CompanionVoicePhase.idle);
    await voice.start(existingText: '');
    expect(voice.phase, CompanionVoicePhase.listening);
    expect(voice.transcript, 'kısmi');
  });

  test('stop returns to idle and keeps transcript for composer', () async {
    final voice = CompanionVoiceController(_LiveFake());
    await voice.start(existingText: '');
    await voice.stop();
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(voice.composerDraft, 'Merhaba OR');
  });

  test('cancel returns to idle without a fake transcript', () async {
    final voice = CompanionVoiceController(_LiveFake());
    await voice.start(existingText: 'Notum:');
    await voice.cancel();
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(voice.transcript, isEmpty);
    expect(voice.composerDraft, 'Notum:');
  });

  test('stop releases the microphone session', () async {
    final port = _LiveFake();
    final voice = CompanionVoiceController(port);
    await voice.start(existingText: '');
    await voice.stop();
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(port.stopCount, greaterThan(0));
    expect(voice.isActive, isFalse);
  });

  test('empty capture fails gracefully and stays idle', () async {
    final voice = CompanionVoiceController(_LiveFake(finalWords: ''));
    await voice.start(existingText: '');
    await voice.stop();
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(voice.composerDraft.trim(), isEmpty);
    expect(voice.errorMessage, CompanionCopy.voiceEmpty);
  });

  test('retry starts a fresh one-shot capture', () async {
    final port = _LiveFake();
    final voice = CompanionVoiceController(port);
    await voice.start(existingText: '');
    await voice.stop();
    await voice.retry(existingText: 'tekrar');
    expect(port.startCount, 2);
    expect(voice.phase, CompanionVoicePhase.listening);
    expect(voice.composerDraft, 'tekrar kısmi');
  });

  test('existing composer text is preserved in the draft', () async {
    final voice = CompanionVoiceController(_LiveFake());
    await voice.start(existingText: 'Notum:');
    expect(voice.composerDraft, 'Notum: kısmi');
    await voice.stop();
    expect(voice.composerDraft, 'Notum: Merhaba OR');
  });

  test('empty transcript does not become a sendable message', () async {
    final voice = CompanionVoiceController(_LiveFake(finalWords: ''));
    await voice.start(existingText: '');
    await voice.stop();
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(voice.composerDraft.trim(), isEmpty);
  });

  test('permission denied returns to idle without fake text', () async {
    final voice = CompanionVoiceController(
      _DeniedFake(permission: CompanionVoicePermission.denied),
    );
    await voice.start(existingText: 'kalır');
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(voice.errorMessage, CompanionCopy.voicePermissionDenied);
    expect(voice.transcript, isEmpty);
  });

  test('speech unavailable returns to idle honestly', () async {
    final voice = CompanionVoiceController(_DeniedFake(available: false));
    await voice.start(existingText: '');
    expect(voice.phase, CompanionVoicePhase.idle);
    expect(voice.errorMessage, CompanionCopy.voiceSpeechUnavailable);
  });

  test('rapid start taps do not open a second listening session', () async {
    final port = _LiveFake();
    final voice = CompanionVoiceController(port);
    await voice.start(existingText: '');
    await voice.start(existingText: '');
    await voice.start(existingText: '');
    expect(port.startCount, 1);
    expect(voice.phase, CompanionVoicePhase.listening);
  });

  testWidgets('transcript populates composer and text send still works', (
    tester,
  ) async {
    final composer = TextEditingController();
    addTearDown(composer.dispose);
    var sent = false;
    final port = _LiveFake();

    await tester.pumpWidget(
      _voiceScope(
        port: port,
        child: _VoiceBar(
          composer: composer,
          onSend: () {
            if (composer.text.trim().isEmpty) return;
            sent = true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    // Live transcript owns the text while listening — composer stays clear.
    expect(composer.text, isEmpty);
    expect(sent, isFalse);

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(composer.text, 'Merhaba OR');
    expect(sent, isFalse);
    expect(port.startCount, 1);

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(sent, isTrue);
  });

  testWidgets('empty transcript does not send', (tester) async {
    final composer = TextEditingController();
    addTearDown(composer.dispose);
    var sent = false;
    final port = _LiveFake(finalWords: '');

    await tester.pumpWidget(
      _voiceScope(
        port: port,
        child: _VoiceBar(
          composer: composer,
          onSend: () {
            if (composer.text.trim().isEmpty) return;
            sent = true;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.mic_none_rounded));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump();

    expect(composer.text.trim(), isEmpty);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(sent, isFalse);
  });
}

Widget _voiceScope({
  required CompanionVoiceInputPort port,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [companionVoiceInputProvider.overrideWithValue(port)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

class _VoiceBar extends ConsumerWidget {
  const _VoiceBar({required this.composer, required this.onSend});

  final TextEditingController composer;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(companionVoiceControllerProvider);
    return CompanionReferenceVoiceListener(
      composer: composer,
      child: CompanionReferenceInputBar(
        controller: composer,
        onSend: onSend,
        voicePhase: voice.phase,
        onMicTap: () async {
          if (voice.isListening) {
            await voice.stop();
            return;
          }
          await voice.start(existingText: composer.text);
        },
      ),
    );
  }
}

class _DeniedFake implements CompanionVoiceInputPort {
  _DeniedFake({
    this.available = true,
    this.permission = CompanionVoicePermission.granted,
  });

  final bool available;
  final CompanionVoicePermission permission;

  @override
  bool get isAvailable => available;

  @override
  Future<bool> isSpeechAvailable() async => available;

  @override
  Future<CompanionVoicePermission> requestPermission() async => permission;

  @override
  Future<void> startListening({
    required void Function(CompanionSpeechResult result) onResult,
    required void Function(CompanionVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    fail('startListening should not run for this fake');
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
}

class _LiveFake implements CompanionVoiceInputPort {
  _LiveFake({this.finalWords = 'Merhaba OR'});

  final String finalWords;
  var startCount = 0;
  var stopCount = 0;
  var cancelCount = 0;
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
    onResult(const CompanionSpeechResult(text: 'kısmi', isFinal: false));
  }

  @override
  Future<void> stopListening() async {
    stopCount += 1;
    final onResult = _onResult;
    final onEnded = _onEnded;
    _onResult = null;
    _onEnded = null;
    onResult?.call(CompanionSpeechResult(text: finalWords, isFinal: true));
    onEnded?.call();
  }

  @override
  Future<void> cancelListening() async {
    cancelCount += 1;
    _onResult = null;
    _onEnded = null;
  }
}

