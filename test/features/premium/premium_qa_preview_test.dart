/// QA preview frames stay labeled and never invent a store price.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/legal/legal_copy.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_legal_disclosure.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_qa_preview.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plans preview is labeled and does not show a currency', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(
          home: PremiumReferenceScreen(qaPreview: PremiumQaPreviewKind.plans),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(PremiumCopy.qaPreview), findsOneWidget);
    expect(find.text('Aylık'), findsOneWidget);
    expect(find.text('Yıllık'), findsOneWidget);
    expect(find.text('Ömür Boyu'), findsOneWidget);
    expect(find.text(PremiumCopy.qaPreviewPrice), findsWidgets);
    expect(find.text(PremiumCopy.qaPreviewCta), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.byType(OraclyGoldButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable preview has no price and no buy button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(
          home: PremiumReferenceScreen(
            qaPreview: PremiumQaPreviewKind.unavailable,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text(PremiumCopy.qaPreview), findsOneWidget);
    expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
    expect(find.text(PremiumCopy.qaPreviewPrice), findsNothing);
    expect(find.byType(OraclyGoldButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unnamed membership does not claim a yearly renewal', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumLegalDisclosure(
            selectedPlan: PremiumPlanKind.yearly,
            namePeriod: false,
          ),
        ),
      ),
    );
    expect(
      find.text('Yıllık otomatik yenilenen abonelik.'),
      findsNothing,
    );
    expect(find.text(LegalCopy.privacyPolicy), findsOneWidget);
  });
}
