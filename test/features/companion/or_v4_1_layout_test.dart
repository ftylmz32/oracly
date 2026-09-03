import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_message_bubble.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_prompts.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thread.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('restored thread settles with newest assistant fully visible', (
    tester,
  ) async {
    OraclyL10n.bind('tr');
    const size = Size(390, 844);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final messages = <AIMessage>[
      for (var i = 0; i < 8; i++)
        AIMessage(
          id: 'm$i',
          role: i.isEven ? AIMessageRole.user : AIMessageRole.assistant,
          content: i == 7
              ? 'En yeni Luna yanıtı tamamen okunur. ${'Yansıma sürüyor. ' * 8}'
              : 'Önceki konuşma $i. ${'Hatıra. ' * 10}',
          createdAt: DateTime(2026, 9, 3, 20, i),
        ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 430,
              child: CompanionReferenceThread(
                scrollController: scroll,
                messages: messages,
                showActions: true,
                allowSpeak: true,
                onSpeak: (_) {},
                onRegenerate: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, closeTo(scroll.position.maxScrollExtent, 1));
    final latest = find.byType(CompanionReferenceMessageBubble).last;
    expect(tester.getBottomLeft(latest).dy, lessThanOrEqualTo(430));
    expect(tester.takeException(), isNull);
  });

  testWidgets('426 width lays out all three prompts without tiny text', (
    tester,
  ) async {
    OraclyL10n.bind('tr');
    await tester.binding.setSurfaceSize(const Size(426, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferencePrompts(
            onSelected: (_) {},
            horizontal: true,
            limit: 3,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CompanionPromptInvitation), findsNWidgets(3));
    for (final text in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(CompanionPromptInvitation),
        matching: find.byType(Text),
      ),
    )) {
      expect(text.style?.fontSize ?? 0, greaterThanOrEqualTo(12));
    }
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow prompt row exposes horizontal-scroll affordance', (
    tester,
  ) async {
    OraclyL10n.bind('tr');
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferencePrompts(
            onSelected: (_) {},
            horizontal: true,
            limit: 3,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CompanionPromptInvitation), findsWidgets);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(find.byType(ListView), const Offset(-260, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
