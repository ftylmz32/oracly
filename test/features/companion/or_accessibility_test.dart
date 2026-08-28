/// OR chamber accessibility - targets, roles, live status, reduced motion.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/accessibility/oracly_a11y.dart';
import 'package:oracly_new/core/theme/oracly_reduced_motion.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_connection_strip.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_new_reply_chip.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_live_transcript.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_output_chip.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_plus_slot.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thinking.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_transcript_review.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_voice_slot.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_phase.dart';

void main() {
  Widget wrap(Widget child, {bool reduceMotion = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduceMotion,
          size: const Size(390, 844),
        ),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('new reply chip meets 44px touch floor', (tester) async {
    await tester.pumpWidget(wrap(CompanionNewReplyChip(onTap: () {})));
    final size = tester.getSize(find.byType(CompanionNewReplyChip));
    expect(size.width, greaterThanOrEqualTo(OraclyA11y.minTouchTarget));
    expect(size.height, greaterThanOrEqualTo(OraclyA11y.minTouchTarget));
  });

  testWidgets('transcript review actions render', (tester) async {
    await tester.pumpWidget(
      wrap(
        CompanionReferenceTranscriptReview(
          visible: true,
          onRetry: () {},
          onConfirm: () {},
        ),
      ),
    );
    expect(find.text(CompanionCopy.voiceReviewRetry), findsOneWidget);
    expect(find.text(CompanionCopy.voiceReviewSend), findsOneWidget);
  });

  testWidgets('voice + plus expose clear semantics', (tester) async {
    await tester.pumpWidget(
      wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompanionReferenceVoiceSlot(
              phase: CompanionVoicePhase.listening,
              onTap: () {},
              onCancel: () {},
            ),
            CompanionReferencePlusSlot(onTap: () {}),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel(CompanionCopy.voiceListening), findsOneWidget);
    expect(find.bySemanticsLabel(CompanionCopy.plusSemantics), findsOneWidget);
  });

  testWidgets('message bubbles announce speaker role', (tester) async {
    final user = AIMessage(
      id: 'u1',
      role: AIMessageRole.user,
      content: 'Merhaba',
      createdAt: DateTime(2026),
    );
    final or = AIMessage(
      id: 'a1',
      role: AIMessageRole.assistant,
      content: 'Dinliyorum',
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      wrap(
        Column(
          children: [
            CompanionReferenceMessageBubble(message: user),
            CompanionReferenceMessageBubble(message: or),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel(CompanionCopy.messageYou), findsOneWidget);
    expect(find.bySemanticsLabel(CompanionCopy.messageOr), findsOneWidget);
    expect(find.text('Merhaba'), findsOneWidget);
    expect(find.text('Dinliyorum'), findsOneWidget);
  });

  testWidgets('status and thinking are live regions', (tester) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            CompanionConnectionStrip(status: CompanionLinkStatus.offline),
            CompanionReferenceThinking(),
            CompanionReferenceLiveTranscript(
              phase: CompanionVoicePhase.listening,
              text: 'selam',
            ),
          ],
        ),
      ),
    );
    final nodes = tester.getSemantics(find.byType(CompanionConnectionStrip));
    expect(nodes.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion), isTrue);
    final thinking =
        tester.getSemantics(find.byType(CompanionReferenceThinking));
    expect(
      thinking.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion),
      isTrue,
    );
  });

  testWidgets('output chip respects reduced motion', (tester) async {
    await tester.pumpWidget(
      wrap(
        CompanionOutputChip(
          selected: true,
          label: 'Yazili',
          semantics: 'Yazili',
          onTap: () {},
        ),
        reduceMotion: true,
      ),
    );
    final ctx = tester.element(find.byType(CompanionOutputChip));
    expect(
      OraclyReducedMotion.duration(ctx, const Duration(milliseconds: 180)),
      Duration.zero,
    );
  });
}