/// Phase 7F.1 — ActivateIntent keyboard paths (Tasks 3–4).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_ux/reading_expand_section.dart';
import 'package:oracly_new/core/reading_ux/reading_ux_copy.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7f1_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('T3 Continue Reading via ActivateIntent expands prose',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(tester, presentation: presentation);
    await tester.pumpAndSettle();

    final continueBtn = phase7f1ContinuePressable();
    expect(continueBtn, findsWidgets);
    final countBefore = continueBtn.evaluate().length;
    expect(countBefore, greaterThan(0));

    final first = continueBtn.first;
    await tester.ensureVisible(first);
    await tester.pump();
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(ReadingUxCopy.continueReading).first,
      ),
      isSemantics(isButton: true, label: ReadingUxCopy.continueReading),
    );

    await phase7f1ActivateFocused(tester, first);
    await tester.pumpAndSettle();

    expect(
      phase7f1ContinuePressable().evaluate().length,
      lessThan(countBefore),
    );
    expect(find.byType(ReadingExpandSection), findsWidgets);
    expect(find.byType(OraclyPressable), findsWidgets);
    handle.dispose();
  });

  testWidgets('T4 fact toggle via ActivateIntent expands deeper facts',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(tester, presentation: presentation);
    final moreLabel = presentation.factSnapshot.moreLabel;
    final toggle = find.byKey(const ValueKey('starFactMoreToggle'));
    await tester.ensureVisible(toggle);
    await tester.pump();

    expect(
      tester.getSemantics(find.bySemanticsLabel(moreLabel)),
      isSemantics(isExpanded: false, hasExpandedState: true, isButton: true),
    );

    await phase7f1ActivateFocused(tester, toggle);
    await tester.pump();

    expect(
      tester.getSemantics(find.bySemanticsLabel(moreLabel)),
      isSemantics(isExpanded: true, hasExpandedState: true, isButton: true),
    );
    handle.dispose();
  });
}
