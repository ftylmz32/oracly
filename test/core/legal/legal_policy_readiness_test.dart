/// Legal / store policy readiness — URLs, disclosures, manage, restore copy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/legal/legal_copy.dart';
import 'package:oracly_new/core/legal/legal_document_kind.dart';
import 'package:oracly_new/core/legal/legal_document_launcher.dart';
import 'package:oracly_new/core/legal/oracly_legal_urls.dart';
import 'package:oracly_new/core/legal/store_subscription_management.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_legal_disclosure.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_cta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('en');
    OraclyLegalUrls.testEnv = null;
  });

  tearDown(() => OraclyLegalUrls.testEnv = null);

  test('monthly disclosure is recurring', () {
    final text = LegalCopy.planDisclosure(PremiumPlanKind.monthly);
    expect(text.toLowerCase(), contains('auto-renew'));
    expect(text.toLowerCase(), contains('monthly'));
    expect(
      PremiumPlanKind.monthly.periodLabel.toLowerCase(),
      contains('auto-renew'),
    );
  });

  test('yearly disclosure is recurring', () {
    final text = LegalCopy.planDisclosure(PremiumPlanKind.yearly);
    expect(text.toLowerCase(), contains('auto-renew'));
    expect(text.toLowerCase(), contains('yearly'));
    expect(
      PremiumPlanKind.yearly.periodLabel.toLowerCase(),
      contains('auto-renew'),
    );
  });

  test('lifetime wording is non-recurring', () {
    final text = LegalCopy.planDisclosure(PremiumPlanKind.lifetime);
    expect(text.toLowerCase(), contains('one-time'));
    expect(text.toLowerCase(), isNot(contains('auto-renew')));
    expect(
      PremiumPlanKind.lifetime.periodLabel.toLowerCase(),
      contains('does not renew'),
    );
  });

  test('missing real Privacy/Terms URL fails honestly', () async {
    OraclyLegalUrls.testEnv = null;
    expect(OraclyLegalUrls.hasPrivacyPolicy, isFalse);
    expect(OraclyLegalUrls.hasTermsOfUse, isFalse);
    expect(
      await LegalDocumentLauncher.open(LegalDocumentKind.privacyPolicy),
      LegalOpenResult.missingUrl,
    );
    expect(
      await LegalDocumentLauncher.open(LegalDocumentKind.termsOfUse),
      LegalOpenResult.missingUrl,
    );
  });

  test('placeholder and http URLs are rejected', () {
    OraclyLegalUrls.testEnv = {
      OraclyLegalUrls.privacyPolicyEnvKey: 'https://example.com/privacy',
      OraclyLegalUrls.termsOfUseEnvKey: 'http://insecure.oracly.app/terms',
    };
    expect(OraclyLegalUrls.privacyPolicyUrl, isNull);
    expect(OraclyLegalUrls.termsOfUseUrl, isNull);
  });

  test('configured HTTPS URLs are accepted', () {
    OraclyLegalUrls.testEnv = {
      OraclyLegalUrls.privacyPolicyEnvKey: 'https://oracly.app/privacy',
      OraclyLegalUrls.termsOfUseEnvKey: 'https://oracly.app/terms',
    };
    expect(OraclyLegalUrls.hasPrivacyPolicy, isTrue);
    expect(OraclyLegalUrls.hasTermsOfUse, isTrue);
    expect(OraclyLegalUrls.privacyPolicyUri?.host, 'oracly.app');
  });

  test('manage-subscription URIs are official store endpoints', () {
    final ios = StoreSubscriptionManagement.uriFor(platform: TargetPlatform.iOS);
    final android =
        StoreSubscriptionManagement.uriFor(platform: TargetPlatform.android);
    expect(ios.host, 'apps.apple.com');
    expect(ios.path, contains('subscriptions'));
    expect(android.host, 'play.google.com');
    expect(android.queryParameters['package'], 'app.oracly');
    expect(
      StoreSubscriptionManagement.isAvailable(platform: TargetPlatform.iOS),
      isTrue,
    );
    expect(
      StoreSubscriptionManagement.isAvailable(platform: TargetPlatform.android),
      isTrue,
    );
  });

  testWidgets('restore purchases remains visible on configured CTA',
      (tester) async {
    var restoreTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumReferenceCta(
            isPremium: false,
            purchaseConfigured: true,
            onActivate: () {},
            onRestore: () => restoreTaps++,
          ),
        ),
      ),
    );
    expect(find.text(PremiumCopy.ctaRestore), findsOneWidget);
    await tester.tap(find.text(PremiumCopy.ctaRestore));
    expect(restoreTaps, 1);
  });

  testWidgets('legal disclosure shows plan + manage + privacy/terms',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumLegalDisclosure(
            selectedPlan: PremiumPlanKind.monthly,
          ),
        ),
      ),
    );
    expect(
      find.text(LegalCopy.planDisclosure(PremiumPlanKind.monthly)),
      findsOneWidget,
    );
    expect(find.text(LegalCopy.manageSubscription), findsOneWidget);
    expect(find.text(LegalCopy.privacyPolicy), findsOneWidget);
    expect(find.text(LegalCopy.termsOfUse), findsOneWidget);
    expect(find.text(LegalCopy.cancelNote), findsOneWidget);
    expect(find.text(LegalCopy.restoreNote), findsOneWidget);
  });

  testWidgets('lifetime disclosure hides cancel auto-renew note', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumLegalDisclosure(
            selectedPlan: PremiumPlanKind.lifetime,
          ),
        ),
      ),
    );
    expect(find.text(LegalCopy.cancelNote), findsNothing);
    expect(
      find.text(LegalCopy.planDisclosure(PremiumPlanKind.lifetime)),
      findsOneWidget,
    );
  });
}