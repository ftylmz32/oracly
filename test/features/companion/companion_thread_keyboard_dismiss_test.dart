/// OR/Luna chat thread must dismiss the keyboard on drag, matching the
/// rest of the app's chat-adjacent scrollables (see tarot_screen_shell.dart
/// and oracly_scroll_body.dart), so a user browsing the conversation with
/// the keyboard open isn't stuck with it blocking the view.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_thread_list.dart';

void main() {
  testWidgets(
    'dragging the OR thread dismisses an open composer keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final now = DateTime(2026, 1, 1);
      final messages = List.generate(
        20,
        (i) => AIMessage(
          id: 'm$i',
          role: i.isEven ? AIMessageRole.user : AIMessageRole.assistant,
          content:
              'Message number $i with enough text to take up real space '
              'in the thread so the list actually needs to scroll.',
          createdAt: now.add(Duration(minutes: i)),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: CompanionReferenceThreadList(
                    scrollController: scrollController,
                    visible: messages,
                    lastOrId: messages.last.id,
                    showActions: false,
                    onSpeak: (_) {},
                    onRegenerate: () {},
                    allowSpeak: false,
                  ),
                ),
                TextField(focusNode: focusNode),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Drag the thread list — this must not leave the keyboard open and
      // covering the conversation.
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.pump();

      expect(
        focusNode.hasFocus,
        isFalse,
        reason: 'ListView.separated in companion_reference_thread_list.dart '
            'must set keyboardDismissBehavior: onDrag so scrolling the '
            'conversation dismisses the keyboard, matching every other '
            'text-input scrollable in the app.',
      );
    },
  );
}
