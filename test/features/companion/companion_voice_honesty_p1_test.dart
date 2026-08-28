/// P1 — OR Rehberi real mic: honest STT, text send unchanged, no fake audio.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_voice_slot.dart';
import 'package:oracly_new/features/companion/services/companion_voice_input_port.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_failure.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_permission.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_phase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unavailable port stays honest and never invents a transcript',
    () async {
      const port = UnavailableCompanionVoiceInput();
      expect(port.isAvailable, isFalse);
      expect(await port.isSpeechAvailable(), isFalse);
      expect(
        await port.requestPermission(),
        CompanionVoicePermission.unavailable,
      );
      CompanionVoiceFailure? failure;
      await port.startListening(
        onResult: (_) => fail('must not fabricate text'),
        onError: (error) => failure = error,
      );
      expect(failure?.kind, CompanionVoiceFailureKind.speechUnavailable);
      expect(failure?.userMessage, CompanionCopy.voiceSpeechUnavailable);
    },
  );

  testWidgets('idle mic is enabled and text send still works', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var sent = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceInputBar(
            controller: controller,
            onSend: () => sent = true,
            onMicTap: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CompanionReferenceVoiceSlot), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_off_rounded), findsNothing);
    expect(
      find.byType(CompanionReferenceVoiceSlot).hitTestable(),
      findsOneWidget,
    );

    final semantics = tester.ensureSemantics();
    try {
      expect(find.bySemanticsLabel(CompanionCopy.voiceLabel), findsOneWidget);
    } finally {
      semantics.dispose();
    }

    expect(find.text(CompanionCopy.voiceComingSoon), findsNothing);
    expect(sent, isFalse);

    controller.text = 'Merhaba OR';
    await tester.pump();
    await tester.tap(find.byIcon(Icons.north_east_rounded));
    await tester.pump();
    expect(sent, isTrue);
  });

  testWidgets('listening mic is active and stoppable', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var stopped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceInputBar(
            controller: controller,
            onSend: () {},
            voicePhase: CompanionVoicePhase.listening,
            onMicTap: () => stopped = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    final semantics = tester.ensureSemantics();
    try {
      expect(
        find.bySemanticsLabel(CompanionCopy.voiceListening),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    expect(stopped, isTrue);
  });

  test('voice copy is Turkish and does not claim continuous listening', () {
    expect(CompanionCopy.voiceLabel, 'Sesli mesaj');
    expect(CompanionCopy.voiceListening, 'Konuş — bitince dokun');
    expect(CompanionCopy.voiceListening.toLowerCase(), isNot(contains('dinleniyor')));
    expect(CompanionCopy.voicePermissionDenied.toLowerCase(), contains('izni'));
    expect(
      CompanionCopy.voiceSpeechUnavailable.toLowerCase(),
      contains('yazarak'),
    );
    for (final copy in [
      CompanionCopy.voiceLabel,
      CompanionCopy.voiceListening,
      CompanionCopy.voicePermissionDenied,
      CompanionCopy.voiceSpeechUnavailable,
      CompanionCopy.voiceSpeechError,
    ]) {
      expect(copy.toLowerCase(), isNot(contains('kaydedildi')));
      expect(copy.toLowerCase(), isNot(contains('sesli yanıt')));
      expect(copy.toLowerCase(), isNot(contains('sürekli')));
    }
  });
}
