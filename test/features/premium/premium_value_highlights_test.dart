import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_value_highlights.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets(
      'verified Premium highlights fit ${size.width.toInt()}px at 1.3x text',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: const Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PremiumReferenceValueHighlights(),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text(PremiumCopy.benefitSoulmateTitle), findsOneWidget);
        expect(find.text(PremiumCopy.benefitOrTitle), findsOneWidget);
        expect(find.text(PremiumCopy.benefitJourneyTitle), findsOneWidget);

        // Coffee and palm are available independently of Premium.
        // The sales strip must never present either as a paid membership perk.
        expect(find.text(PremiumCopy.benefitCoffeeTitle), findsNothing);
        expect(find.text(PremiumCopy.benefitPalmTitle), findsNothing);
        expect(find.textContaining('₺'), findsNothing);
      },
    );
  }
}
