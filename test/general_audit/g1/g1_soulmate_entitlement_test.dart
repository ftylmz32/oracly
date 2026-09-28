/// G1 — SoulMate: Premium is checked at every paid step, a saved portrait
/// stays readable after a lapse, and a repair updates the same Journal row.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/economy/soul_mate_economy.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_result_view.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_providers.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_saved_provider.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';

import 'g1_soulmate_fakes.dart';
import 'g1_soulmate_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(PremiumDevOverride.resetDebug);
  tearDown(PremiumDevOverride.resetDebug);

  test('SoulMate is a Premium feature with no Gem price', () {
    expect(SoulMateEconomy.drawCost, isNull);
    expect(SoulMateEconomy.hasCost, isFalse);
  });

  Future<(G1SoulMateHarness, G1MemorySoulMateJournal, G1CountingInterpretation)>
      openSavedPartial(WidgetTester tester) async {
    final harness = await G1SoulMateHarness.open();
    final journal = G1MemorySoulMateJournal(harness.storage);
    await journal.saveSuccessfulDraw(
      request: SoulMateDrawRequest(name: 'Ada', birthDate: DateTime(1994, 3, 12)),
      imageBytes: g1Png,
      recordId: 'g1-saved-partial',
    );
    final interpretation = G1CountingInterpretation();
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness.screen(extra: [
      soulMateResultServiceProvider.overrideWithValue(journal),
      soulMateInterpretationPortProvider.overrideWithValue(interpretation),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(SoulMateCopy.interpretationFailed), findsOneWidget);
    return (harness, journal, interpretation);
  }

  Future<void> tapRepair(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text(SoulMateCopy.retry), 120);
    await tester.tap(find.text(SoulMateCopy.retry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('after Premium lapses a saved portrait stays readable but '
      'no new interpretation is generated', (tester) async {
    final (harness, journal, interpretation) = await openSavedPartial(tester);
    harness.lapse();

    await tapRepair(tester);

    expect(interpretation.calls, 0);
    expect(harness.status.isPremium, isFalse);
    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(journal.rows.keys, ['g1-saved-partial']);
  });

  testWidgets('repairing a restored portrait updates its own Journal row',
      (tester) async {
    final (_, journal, interpretation) = await openSavedPartial(tester);

    await tapRepair(tester);

    expect(interpretation.calls, 1);
    expect(journal.rows.keys, ['g1-saved-partial']);
    expect(journal.rows['g1-saved-partial']!.hasAuthoritativeInterpretation,
        isTrue);
  });

  testWidgets('a double tap during a slow Premium check submits one draw',
      (tester) async {
    final harness = await G1SoulMateHarness.open();
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness.screen(extra: [
      soulMateResultServiceProvider
          .overrideWithValue(G1MemorySoulMateJournal(harness.storage)),
    ]));
    await tester.pump();
    await g1FillSoulMateForm(tester);
    harness.stale();
    final hold = harness.verifier.hold = Completer<void>();

    await tester.tap(find.text(SoulMateCopy.drawCta));
    await tester.tap(find.text(SoulMateCopy.drawCta));
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.transport.creates, 1);
    expect(find.text(SoulMateCopy.drawing), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}
