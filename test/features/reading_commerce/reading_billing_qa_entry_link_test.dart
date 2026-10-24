import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/reading_commerce/copy/reading_commerce_copy.dart';
import 'package:oracly_new/features/reading_commerce/presentation/reading_billing_qa_entry_link.dart';
import 'package:oracly_new/features/reading_commerce/presentation/reading_commerce_screen.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_binding.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_monitor.dart';
import 'package:oracly_new/features/reading_commerce/services/reading_purchase_tracker.dart';
import 'package:oracly_new/features/reading_operation/providers/reading_live_provider.dart';

void main() {
  testWidgets('a store build does not show the QA purchase link', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ReadingBillingQaEntryLink()),
    ));
    expect(find.text(ReadingCommerceCopy.billingQaEntry), findsNothing);
  });

  testWidgets('the QA link opens the purchase screen', (tester) async {
    final monitor = ReadingPurchaseMonitor(
      tracker: ReadingPurchaseTracker(
        memory: MemoryReadingPurchases(),
        verify: (_) async => ReadingVerifyOutcome.unavailable,
        complete: (_) async {},
      ),
      updates: const Stream.empty(),
      buyProduct: (_) async => false,
      storePrices: () async => const {},
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        readingPurchaseMonitorProvider.overrideWithValue(monitor),
        readingOperationSenderProvider.overrideWith((ref) => null),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ReadingBillingQaEntryLink(forceEnabled: true)),
      ),
    ));
    await tester.tap(find.text(ReadingCommerceCopy.billingQaEntry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ReadingCommerceScreen), findsOneWidget);
    await monitor.dispose();
  });
}
