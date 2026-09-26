/// Phase 7F.1 — fact toggle hit target + semantics (Tasks 1–2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_fact_snapshot_plate.dart';

import '../../../visual/yildizname/yildizname_visual_harness.dart';
import 'phase7f1_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await yildiznameVisualBindLocale('tr');
  });

  testWidgets('T1 fact toggle rendered hit region ≥44×44', (tester) async {
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(tester, presentation: presentation);
    final toggle = find.byKey(const ValueKey('starFactMoreToggle'));
    expect(toggle, findsOneWidget);
    final size = tester.getSize(toggle);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('T2 fact toggle semantics closed→open; one button',
      (tester) async {
    final handle = tester.ensureSemantics();
    final presentation = await phase7f1FullPresentation();
    await phase7f1Pump(tester, presentation: presentation);

    final plate = find.byType(StarMapFactSnapshotPlate);
    expect(plate, findsOneWidget);
    final moreLabel = presentation.factSnapshot.moreLabel;
    expect(moreLabel, isNotEmpty);

    final root = tester.getSemantics(find.byType(StarMapFactSnapshotPlate));
    expect(phase7f1ButtonCount(root, moreLabel), 1);
    final closed = tester.getSemantics(find.bySemanticsLabel(moreLabel));
    expect(
      closed,
      isSemantics(
        label: moreLabel,
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('starFactMoreToggle')));
    await tester.tap(find.byKey(const ValueKey('starFactMoreToggle')));
    await tester.pump();

    final openRoot = tester.getSemantics(find.byType(StarMapFactSnapshotPlate));
    expect(phase7f1ButtonCount(openRoot, moreLabel), 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel(moreLabel)),
      isSemantics(
        label: moreLabel,
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
      ),
    );
    handle.dispose();
  });
}
