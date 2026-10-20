import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_commerce/copy/reading_commerce_copy.dart';
import 'package:oracly_new/features/reading_commerce/presentation/reading_credit_link.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_monitor.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_tracker.dart';
import 'package:flutter/material.dart';

ReadingPurchaseUpdate purchased(String token) => ReadingPurchaseUpdate(
      productId: 'app.oracly.reading.coffee',
      token: token,
      purchaseId: 'id-$token',
      status: ReadingPurchaseStatus.purchased,
    );

void main() {
  test('pending is not granted, and a later purchase survives a closed app', () async {
    final memory = MemoryReadingPurchases();
    var verifies = 0;
    var completes = 0;
    final credits = <String>{};
    Future<ReadingVerifyOutcome> verify(ReadingPurchaseUpdate update) async {
      verifies += 1;
      if (update.token == 'offline') throw StateError('down');
      credits.add(update.token);
      return ReadingVerifyOutcome.granted;
    }

    final first = ReadingPurchaseTracker(memory: memory, verify: verify, complete: (_) async => completes++);
    expect(
      await first.accept(const ReadingPurchaseUpdate(
        productId: 'app.oracly.reading.coffee',
        token: 'pending-token',
        purchaseId: 'p',
        status: ReadingPurchaseStatus.pending,
      )),
      ReadingBuyKind.pending,
    );
    expect(verifies, 0);
    expect(completes, 0);

    expect(await first.accept(purchased('offline')), ReadingBuyKind.failed);
    expect(completes, 0);
    expect(
      (await memory.load()).map((item) => item.token),
      containsAll(['pending-token', 'offline']),
    );

    final reopened = ReadingPurchaseTracker(
      memory: memory,
      verify: (update) async {
        credits.add(update.token);
        return ReadingVerifyOutcome.granted;
      },
      complete: (update) async {
        completes += 1;
        expect(update.token, 'offline');
      },
    );
    await reopened.resume();
    expect(credits, {'offline'});
    expect(completes, 1);
    expect((await memory.load()).map((item) => item.token), ['pending-token']);

    await reopened.accept(purchased('offline'));
    expect(credits, {'offline'});
    expect(completes, 2);
  });

  test('a purchase that arrives after the wait is still verified', () async {
    final memory = MemoryReadingPurchases();
    final updates = StreamController<List<ReadingPurchaseUpdate>>();
    var completes = 0;
    final monitor = ReadingPurchaseMonitor(
      tracker: ReadingPurchaseTracker(
        memory: memory,
        verify: (_) async => ReadingVerifyOutcome.granted,
        complete: (_) async => completes++,
      ),
      updates: updates.stream,
      buyProduct: (_) async => true,
      storePrices: () async => const {},
      buyTimeout: const Duration(milliseconds: 30),
    );
    await monitor.start();
    final timedOut = monitor.buy('app.oracly.reading.palm');
    expect(await timedOut, ReadingBuyKind.pending);
    ReadingBuyKind? settled;
    monitor.addListener((kind, _) => settled = kind);
    updates.add([purchased('late')]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(settled, ReadingBuyKind.granted);
    expect(completes, 1);
    expect(await memory.load(), isEmpty);
    await monitor.dispose();
    await updates.close();
  });

  testWidgets('coffee and palm share a credit link with no price and no buy button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReadingCreditLink()));
    expect(find.text(ReadingCommerceCopy.openCredits), findsOneWidget);
    expect(find.text(ReadingCommerceCopy.buy), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
  });
}
