import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/legal/legal_copy.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_legal_disclosure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final plan in PremiumPlanKind.values) {
    testWidgets(
      'Premium disclosures stay readable for ${plan.name} at 320px',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: PremiumLegalDisclosure(selectedPlan: plan),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(LegalCopy.planDisclosure(plan)), findsOneWidget);
        expect(find.text(LegalCopy.storeBillingNote), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(LegalCopy.storeBillingNote)).style?.fontStyle,
          FontStyle.normal,
        );

        if (plan == PremiumPlanKind.lifetime) {
          expect(find.text(LegalCopy.cancelNote), findsNothing);
        } else {
          expect(find.text(LegalCopy.cancelNote), findsOneWidget);
        }
        expect(find.text(LegalCopy.privacyPolicy), findsOneWidget);
        expect(find.text(LegalCopy.termsOfUse), findsOneWidget);
      },
    );
  }
}
