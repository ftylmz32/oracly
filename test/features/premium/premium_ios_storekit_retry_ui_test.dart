/// iOS Premium unavailable plaque — Retry checking state and the hidden
/// long-press diagnostics gate.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';

import 'support/ios_premium_screen_harness.dart';
import 'support/ios_storekit_fake.dart';

Future<void> _tapRetry(WidgetTester tester) async {
  await tester.ensureVisible(find.text(PremiumCopy.ctaRetryStore));
  await tester.pump();
  await tester.tap(find.text(PremiumCopy.ctaRetryStore));
  await tester.pump();
}

Future<void> _hold(WidgetTester tester, Duration hold) async {
  final target = find.text(PremiumCopy.ctaUnavailable);
  await tester.ensureVisible(target);
  await tester.pump();
  final gesture = await tester.startGesture(tester.getCenter(target));
  await tester.pump(hold);
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  iosPremiumTest('Retry immediately shows the announced checking state, then '
      'recovers when StoreKit returns products', (tester) async {
    final handle = tester.ensureSemantics();
    final iap = FakeStoreKit();
    await pumpIosPremium(tester, iap);
    final gate = Completer<void>();
    iap
      ..products = [monthlyProduct, yearlyProduct]
      ..queryGate = gate;

    await _tapRetry(tester);
    expect(find.text(PremiumCopy.ctaCheckingStore), findsOneWidget);
    expect(find.text(PremiumCopy.ctaRetryStore), findsNothing);
    expect(
      find.ancestor(
        of: find.text(PremiumCopy.ctaCheckingStore),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      ),
      findsOneWidget,
    );

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(PremiumCopy.ctaCheckingStore), findsNothing);
    expect(find.text('STORE-MONTHLY'), findsOneWidget);
    expect(find.text('STORE-YEARLY'), findsOneWidget);
    expect(find.text(PremiumCopy.ctaUnavailable), findsNothing);
    handle.dispose();
  });

  iosPremiumTest('Retry cannot double-fire while checking; state clears when '
      'the store still returns nothing', (tester) async {
    final iap = FakeStoreKit();
    await pumpIosPremium(tester, iap);
    final before = iap.queriedIds.length;
    final gate = Completer<void>();
    iap.queryGate = gate;

    await _tapRetry(tester);
    expect(iap.queriedIds.length, before + 1);
    await tester.tap(find.text(PremiumCopy.ctaCheckingStore));
    await tester.pump();
    expect(iap.queriedIds.length, before + 1, reason: 'no second check');

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(iap.queriedIds.length, before + 2, reason: 'one built-in retry');
    expect(find.text(PremiumCopy.ctaCheckingStore), findsNothing);
    expect(find.text(PremiumCopy.ctaRetryStore), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('storekit'), findsNothing);
  });

  iosPremiumTest('diagnostics gate: hidden, short hold ignored, 2 s hold '
      'opens safe diagnostics that can be copied', (tester) async {
    final handle = tester.ensureSemantics();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await pumpIosPremium(tester, FakeStoreKit());

    expect(
      tester
          .getSemantics(find.text(PremiumCopy.ctaUnavailable))
          .getSemanticsData()
          .hasAction(SemanticsAction.longPress),
      isFalse,
    );
    await _hold(tester, const Duration(seconds: 1));
    expect(find.text(PremiumCopy.storeDiagnosticsTitle), findsNothing);

    await _hold(tester, const Duration(milliseconds: 2100));
    expect(find.text(PremiumCopy.storeDiagnosticsTitle), findsOneWidget);
    expect(find.textContaining('storeAvailable: true'), findsOneWidget);
    expect(find.textContaining('notFound: '), findsOneWidget);

    await tester.ensureVisible(find.text(PremiumCopy.storeDiagnosticsCopy));
    await tester.pump();
    await tester.tap(find.text(PremiumCopy.storeDiagnosticsCopy));
    await tester.pump();
    expect(copied, startsWith('ORACLY store diagnostics'));
    expect(copied, contains('attempt: 2'));
    expect(copied, contains('returned: (none)'));
    expect(find.text(PremiumCopy.storeDiagnosticsCopied), findsOneWidget);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    handle.dispose();
  });
}
