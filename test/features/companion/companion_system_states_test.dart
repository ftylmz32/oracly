/// OR system states — empty, loading, error, retry, offline, speaking.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_idle.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_notice.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thinking.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';

void main() {
  test('empty, loading, error, offline, and retry copy stay human', () {
    expect(CompanionCopy.idleTitle, contains('Luna'));
    expect(CompanionCopy.idleSubtitle.toLowerCase(), contains('duygular'));
    expect(
      OrLivingVoice.thinkingPool(OrLivingSurface.or),
      contains(CompanionCopy.thinking),
    );
    expect(CompanionCopy.speaking.toLowerCase(), contains('konuşuyor'));
    expect(CompanionCopy.stopSpeaking, 'DURDUR');
    expect(CompanionCopy.retry, 'Tekrar dene');
    expect(CompanionCopy.connectionError, contains("OR'a ulaşamadım"));
    expect(CompanionCopy.connectionError, contains('Bir daha deneyelim'));
    expect(CompanionCopy.offline.toLowerCase(), contains('bağlantı kurulamadı'));
    expect(CompanionCopy.connectionError.toLowerCase(), isNot(contains('went wrong')));
    expect(CompanionCopy.offline, isNot(contains("OR'a ulaşamadım")));
    expect(CompanionCopy.connectionError, isNot(contains('Bağlantı kurulamadı')));
  });

  test('offline is distinct from a retryable error', () {
    expect(AiFailure.network().kind, AiFailureKind.network);
    expect(
      const AiRequestException(AiFailure(AiFailureKind.network, 'x')).failure.kind,
      AiFailureKind.network,
    );
  });

  testWidgets('empty is the quiet invite, not an illustration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CompanionReferenceIdle(onSelected: (_) {})),
      ),
    );
    await tester.pump();
    expect(find.text(CompanionCopy.idleTitle), findsOneWidget);
    expect(find.text(CompanionCopy.idleSubtitle), findsOneWidget);
    expect(find.text(CompanionCopy.idleOptional), findsOneWidget);
    expect(find.text(CompanionCopy.presence), findsNothing);
    expect(find.byType(OraclyErrorState), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('thinking has copy and no spinner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CompanionReferenceThinking())),
    );
    await tester.pump();
    expect(find.text(CompanionCopy.thinking), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('error shows two-line copy and TEKRAR DENE', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionReferenceErrorBody(
          message: CompanionCopy.connectionError,
          onRetry: () {},
        ),
      ),
    );
    expect(find.text(CompanionCopy.connectionError), findsOneWidget);
    expect(find.text(CompanionCopy.retry), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('speaking shows OR konuşuyor, DURAKLAT and DURDUR', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOutputMode(
            mode: OrChatOutputMode.voice,
            speaking: true,
            onChanged: (_) {},
            onStop: () {},
            onPauseToggle: () {},
          ),
        ),
      ),
    );
    expect(find.text(CompanionCopy.speaking), findsOneWidget);
    expect(find.text(CompanionCopy.pauseSpeaking), findsOneWidget);
    expect(find.text(CompanionCopy.stopSpeaking), findsOneWidget);
  });

  testWidgets('paused state and replay stay clear', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOutputMode(
            mode: OrChatOutputMode.voice,
            speaking: true,
            paused: true,
            onChanged: (_) {},
            onStop: () {},
            onPauseToggle: () {},
          ),
        ),
      ),
    );
    expect(find.text(CompanionCopy.paused), findsOneWidget);
    expect(find.text(CompanionCopy.resumeSpeaking), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOutputMode(
            mode: OrChatOutputMode.voice,
            canReplay: true,
            onChanged: (_) {},
            onReplay: () {},
          ),
        ),
      ),
    );
    expect(find.text(CompanionCopy.replaySpeaking), findsOneWidget);
  });
}

