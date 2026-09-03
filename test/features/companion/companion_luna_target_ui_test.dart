/// Luna target UI — empty/chat chrome, composer, shortcuts, no shell nav.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_feature_shortcuts.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_luna_intro_card.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_idle.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
  ];

  testWidgets('empty Luna shows intro, prompts, shortcuts, privacy', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = TextEditingController();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(child: CompanionReferenceIdle(onSelected: (_) {})),
              CompanionReferenceInputBar(controller: c, onSend: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CompanionLunaIntroCard), findsOneWidget);
    expect(find.text(CompanionCopy.idleTitle), findsOneWidget);
    expect(find.byType(CompanionFeatureShortcuts), findsOneWidget);
    expect(find.text(CompanionCopy.privacyNote), findsOneWidget);
    expect(find.text(ConversationCopy.inputHint), findsOneWidget);
    expect(find.byType(OraclyBottomBar), findsNothing);
    expect(find.text('Ana Sayfa'), findsNothing);
  });

  testWidgets('user and Luna bubbles render with real text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              CompanionReferenceMessageBubble(
                message: AIMessage(
                  id: 'u1',
                  role: AIMessageRole.user,
                  content: 'Bugun kendimi huzursuz hissediyorum',
                  createdAt: DateTime(2026, 9, 1, 18, 42),
                ),
              ),
              CompanionReferenceMessageBubble(
                message: AIMessage(
                  id: 'a1',
                  role: AIMessageRole.assistant,
                  content: 'Bu his bir sey soyluyor olabilir. Biraz daha anlat.',
                  createdAt: DateTime(2026, 9, 1, 18, 43),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('huzursuz'), findsOneWidget);
    expect(find.textContaining('anlat'), findsOneWidget);
  });

  testWidgets('composer send requires text and fires once', (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceInputBar(
            controller: c,
            onSend: () => sent++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(sent, 0);
    await tester.enterText(find.byType(TextField), 'Merhaba Luna');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(sent, 1);
  });

  testWidgets('mic and plus slots stay wired; keyboard leaves composer reachable',
      (tester) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            viewInsets: EdgeInsets.only(bottom: 280),
            disableAnimations: true,
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      CompanionReferenceMessageBubble(
                        message: AIMessage(
                          id: 'a1',
                          role: AIMessageRole.assistant,
                          content: List.filled(12, 'Uzun Luna yaniti. ').join(),
                          createdAt: DateTime(2026, 9, 1, 18, 43),
                        ),
                      ),
                    ],
                  ),
                ),
                CompanionReferenceInputBar(
                  controller: c,
                  onSend: () {},
                  onMicTap: () {},
                  onPlusTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byType(CompanionReferenceInputBar), findsOneWidget);
    final bar = tester.getRect(find.byType(CompanionReferenceInputBar));
    expect(bar.bottom, lessThanOrEqualTo(640));
  });

  for (final size in viewports) {
    testWidgets('Luna idle fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            oraclyAiServiceProvider.overrideWithValue(
              const UnconfiguredOraclyAiService(allowsLocalFallback: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(size: size, disableAnimations: true),
              child: const CompanionReferenceScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(OraclyBottomBar), findsNothing);
      expect(find.text(CompanionCopy.screenTitle), findsWidgets);
    });
  }
}
