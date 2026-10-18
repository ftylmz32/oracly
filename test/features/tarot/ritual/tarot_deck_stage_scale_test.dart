/// Deck stage keeps the collectible-size card on tall phones and shrinks it
/// (never overflowing) on short or narrow tables.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_deck_stage.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_deck_stack.dart';

import '../../../visual/tarot/tarot_golden_harness.dart';

void main() {
  group('TarotTableDeckStage.scaleFor', () {
    test('full or larger card when the table is tall', () {
      expect(TarotTableDeckStage.scaleFor(const Size(360, 600)), greaterThan(1));
      expect(
        TarotTableDeckStage.scaleFor(const Size(800, 1200)),
        closeTo(1.12, 0.001),
      );
    });

    test('shrinks on short tables but keeps a readable floor', () {
      final short = TarotTableDeckStage.scaleFor(const Size(320, 300));
      expect(short, lessThan(1));
      expect(short, greaterThanOrEqualTo(0.62));
      expect(TarotTableDeckStage.scaleFor(const Size(200, 100)), 0.62);
    });

    test('unbounded constraints fall back to natural size', () {
      expect(
        TarotTableDeckStage.scaleFor(const Size(double.infinity, 500)),
        1,
      );
    });
  });

  for (final viewport in const [Size(320, 568), Size(390, 844), Size(800, 1280)]) {
    testWidgets('intention table renders without overflow at $viewport', (
      tester,
    ) async {
      await tarotGoldenPumpIntention(tester, viewport: viewport);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RitualDeckStack), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
