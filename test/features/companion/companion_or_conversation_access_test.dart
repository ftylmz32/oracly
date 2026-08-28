/// OR conversation Premium gate — paywall honesty, no fake unlock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_paywall.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_premium_sample.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_premium_value.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_cta_unavailable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sample conversation is labeled and not sold as personal',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CompanionReferenceOrPremiumSample()),
      ),
    );
    await tester.pump();
    expect(find.text(CompanionCopy.orPremiumSampleLabel), findsOneWidget);
    expect(find.text(CompanionCopy.orPremiumSampleNote), findsOneWidget);
    expect(CompanionCopy.orPremiumSampleNote.toLowerCase(), contains('örnek'));
  });

  testWidgets('OR paywall shows conversation pillars without life promises',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CompanionReferenceOrPaywall(
              entitlement: PremiumEntitlementState.unavailable,
              purchaseConfigured: false,
              onPurchase: () {},
              onRestore: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(CompanionCopy.orPaywallTitle), findsOneWidget);
    expect(find.text(CompanionCopy.orPaywallPillarDepthTitle), findsOneWidget);
    expect(find.text(CompanionCopy.orPaywallPillarVoiceTitle), findsOneWidget);
    expect(find.text(CompanionCopy.orPaywallPillarContextTitle), findsOneWidget);
    expect(find.text(CompanionCopy.orPaywallHonesty), findsOneWidget);
    expect(find.text(CompanionCopy.orPaywallCta), findsNothing);
    expect(find.byType(PremiumReferenceCtaUnavailable), findsOneWidget);
    for (final line in [
      CompanionCopy.orPaywallHonesty,
      CompanionCopy.orPaywallPillarDepthBody,
      CompanionCopy.orPaywallPillarDiscoveryBody,
    ]) {
      expect(line.toLowerCase(), isNot(contains('kaçırma')));
      expect(line.toLowerCase(), isNot(contains('hemen')));
      expect(line.toLowerCase(), isNot(contains('sınırlı süre')));
    }
    expect(
      CompanionCopy.orPaywallHonesty.toLowerCase(),
      contains('vaat etmez'),
    );
  });

  testWidgets('OR commerce shows OR CTA when store is configured', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionReferenceOrPremiumValue(
            isPremium: false,
            purchaseConfigured: true,
            onPurchase: () {},
            onRestore: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(CompanionCopy.orPaywallCta), findsOneWidget);
    expect(find.text(PremiumCopy.ctaRestore), findsOneWidget);
    expect(find.byType(PremiumReferenceCtaUnavailable), findsNothing);
  });

  test('OR is flagship Premium in catalogue and unlock list', () {
    final or = PremiumCatalogue.premiumExperiences
        .where((b) => b.action == PremiumBenefitAction.companion);
    expect(or, isNotEmpty);
    expect(or.first.requiresPremium, isTrue);
    expect(
      PremiumCatalogue.showcaseBenefits.map((b) => b.title),
      contains(PremiumCopy.benefitOrTitle),
    );
  });
}
