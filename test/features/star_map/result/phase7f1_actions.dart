/// Phase 7F.1 — ActivateIntent + content-width helpers (test-only).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/reading_ux/reading_ux_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_result_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';

Future<void> phase7f1ActivateFocused(
  WidgetTester tester,
  Finder host,
) async {
  expect(host, findsOneWidget);
  final focusFinder = find.descendant(of: host, matching: find.byType(Focus));
  expect(focusFinder, findsWidgets);
  final state = tester.state(focusFinder.first);
  final node = (state as dynamic).focusNode as FocusNode;
  node.requestFocus();
  await tester.pump();
  expect(node.hasFocus, isTrue);

  final actions = find.descendant(of: host, matching: find.byType(Actions));
  expect(actions, findsWidgets);
  final invokeAt = find.descendant(
    of: actions.first,
    matching: find.byType(Semantics),
  );
  expect(invokeAt, findsWidgets);
  Actions.invoke<ActivateIntent>(
    tester.element(invokeAt.first),
    const ActivateIntent(),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder phase7f1ContinuePressable() => find.byWidgetPredicate(
      (w) => w is OraclyPressable && w.label == ReadingUxCopy.continueReading,
    );

Size phase7f1ContentColumnSize(WidgetTester tester) {
  final box = find.descendant(
    of: find.byType(StarMapReferenceResultScreen),
    matching: find.byWidgetPredicate(
      (w) =>
          w is ConstrainedBox &&
          w.constraints.maxWidth == AppLayout.maxContentWidth,
    ),
  );
  expect(box, findsOneWidget);
  return tester.getSize(box);
}
