/// G1 — SoulMate durable observation: a network outage is not an answer,
/// and a redraw after a deep link observes the new operation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_saved_provider.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';

import 'g1_soulmate_fakes.dart';
import 'g1_soulmate_support.dart';

typedef _Opened = (G1SoulMateHarness, G1MemorySoulMateJournal, String?);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(PremiumDevOverride.resetDebug);
  tearDown(PremiumDevOverride.resetDebug);

  /// [target] seeds the backend and returns the deep-linked operation id.
  Future<_Opened> open(
    WidgetTester tester, {
    Future<String> Function(G1SoulMateHarness)? target,
  }) async {
    final harness = await G1SoulMateHarness.open();
    final operationId = await target?.call(harness);
    final journal = G1MemorySoulMateJournal(harness.storage);
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(harness.screen(
      operationId: operationId,
      extra: [soulMateResultServiceProvider.overrideWithValue(journal)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return (harness, journal, operationId);
  }

  Future<void> finishOnServer(
    WidgetTester tester,
    G1SoulMateHarness harness,
    String id,
  ) async {
    harness.completeServerSide(id);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
  }

  testWidgets('an outage while waiting keeps observing until the portrait is '
      'ready', (tester) async {
    final (harness, journal, _) = await open(tester);
    await g1FillSoulMateForm(tester);
    await tester.tap(find.text(SoulMateCopy.drawCta));
    await tester.pump();
    final id = await harness.activeOperationId();
    expect(id, isNotNull);

    harness.transport.dropActive = 2;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(SoulMateCopy.drawing), findsWidgets);

    await finishOnServer(tester, harness, id!);
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
    expect((await journal.latestMeta())?.id, id);
    expect(harness.transport.creates, 1);
  });

  testWidgets('an outage on a deep-linked operation is not "unavailable"',
      (tester) async {
    final (harness, _, target) = await open(
      tester,
      target: (h) async {
        final id = await h.seedOperation('g1-exact-outage-01aaaaaaaaaaaaaaaaaaaaaa');
        h.transport.dropExact = 1;
        return id;
      },
    );

    expect(find.text(SoulMateCopy.unavailable), findsNothing);
    expect(find.text(SoulMateCopy.drawing), findsWidgets);

    await finishOnServer(tester, harness, target!);
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
  });

  testWidgets('a redraw after a deep-linked result observes the new draw',
      (tester) async {
    final (harness, journal, target) = await open(
      tester,
      target: (h) async {
        final id = await h.seedOperation('g1-deep-link-01aaaaaaaaaaaaaaaaaaaaaaaaaa');
        h.completeServerSide(id);
        return id;
      },
    );
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);

    await tester.scrollUntilVisible(find.text(SoulMateCopy.redrawCta), 120);
    await tester.pump();
    await tester.tap(find.text(SoulMateCopy.redrawCta));
    await tester.pump();
    await g1FillSoulMateForm(tester);
    await tester.tap(find.text(SoulMateCopy.drawCta));
    await tester.pump();
    final fresh = await harness.activeOperationId();
    expect(fresh, allOf(isNotNull, isNot(target)));

    await tester.pump(const Duration(seconds: 4));
    expect(find.text(SoulMateCopy.redrawCta), findsNothing);
    expect(find.text(SoulMateCopy.drawing), findsWidgets);

    await finishOnServer(tester, harness, fresh!);
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
    expect((await journal.latestMeta())?.id, fresh);
  });
}
