import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_handoff_banner.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_or_living_core.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_prompt_invitation.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_app_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_idle.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_premium_preview.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_send_button.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thinking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('OR visual master — living core and invitations', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              height: 800,
              child: Column(
                children: [
                  Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
                  CompanionReferenceInputBar(
                    controller: controller,
                    onSend: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(CompanionOrLivingCore), findsOneWidget);
    expect(find.text(CompanionCopy.idleTitle), findsOneWidget);
    expect(find.byType(CompanionPromptInvitation), findsWidgets);
    expect(find.byType(CompanionReferenceSendButton), findsOneWidget);
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
  });

  testWidgets('OR 360x760 fits with four collapsed starters', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 760), disableAnimations: true),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              height: 760,
              child: Column(
                children: [
                  Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
                  CompanionReferenceInputBar(
                    controller: controller,
                    onSend: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CompanionPromptInvitation), findsNWidgets(4));
    expect(find.text(CompanionCopy.plusLabel), findsOneWidget);
    expect(
      tester.getRect(find.byType(CompanionReferenceInputBar)).bottom,
      lessThanOrEqualTo(760),
    );
  });

  testWidgets('OR messages, thinking, ribbon, premium preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ListView(
              children: [
                const CompanionReferenceThinking(),
                CompanionReferenceMessageBubble(
                  message: AIMessage(
                    id: 'a1',
                    role: AIMessageRole.assistant,
                    content: 'Uzun bir yansima cumlesi.',
                    createdAt: DateTime(2026),
                  ),
                ),
                CompanionReferenceMessageBubble(
                  message: AIMessage(
                    id: 'u1',
                    role: AIMessageRole.user,
                    content: 'Kisa not',
                    createdAt: DateTime(2026),
                  ),
                ),
                CompanionHandoffBanner(
                  compact: 'Tarot\nBugunun karti',
                ),
                const CompanionReferenceOrPremiumPreview(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CompanionOrLivingCore), findsWidgets);
    expect(find.text(CompanionCopy.thinking), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
