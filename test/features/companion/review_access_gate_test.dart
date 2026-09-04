/// Regression: a granted Google Play / App Store reviewer access must
/// unlock the SAME OR/companion gates real Premium unlocks — see the bug
/// where `PremiumAccess.ensure` was fixed but downstream OR gates
/// (`CompanionOrConversationAccess`, `OrSessionResolver`,
/// `CompanionReferenceOrPaywall`) still read commerce-only entitlement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/data/repositories/review_access_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/or_session_state.dart';
import 'package:oracly_new/features/companion/services/companion_or_conversation_access.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_paywall.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_paywall_host.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/models/review_access_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_cta.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_access.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/review_access_service.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ActiveVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;
  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => PremiumVerifyResult.active();
}

class _PendingVerifier implements PremiumEntitlementVerifier {
  @override
  bool get isRemoteVerifierConfigured => true;
  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async => PremiumVerifyResult.pending('server_processing');
}

class _ConfiguredPort implements PremiumPurchasePort {
  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {}
  @override
  String? priceLabel(PremiumPlanKind plan) => null;
  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async =>
      PremiumPurchaseResult.failed();
  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.restoreFailed();
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

class _FakeReviewAccessService implements ReviewAccessService {
  String? validCode = 'PLAY-REVIEW-1';
  @override
  bool get isConfigured => true;
  @override
  Future<ReviewAccessResult> activate(String code) async =>
      code == validCode
          ? ReviewAccessResult.granted()
          : ReviewAccessResult.denied('invalid_code');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<
    (ProviderContainer, MockPremiumRepository, _FakeReviewAccessService)
  >
  buildContainer({bool storeConfigured = false}) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final secure = InMemorySecureStorage();
    final premium = MockPremiumRepository(storage, secureStorage: secure);
    final users = MockUserRepository(storage);
    final reviewRepo = ReviewAccessRepository(storage, secureStorage: secure);
    final reviewService = _FakeReviewAccessService();
    final service = PremiumService(
      premium,
      users,
      storeConfigured ? _ConfiguredPort() : const UnavailablePremiumPurchase(),
      storeConfigured ? _ActiveVerifier() : null,
      reviewRepo,
      reviewService,
    );
    final container = ProviderContainer(
      overrides: [premiumServiceProvider.overrideWithValue(service)],
    );
    return (container, premium, reviewService);
  }

  Future<BuildContext> pumpHost(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    late BuildContext captured;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
    await tester.pump();
    // Settle the provider's own initial unawaited load() so no in-flight
    // notifyListeners() races container.dispose() at the end of a test.
    await container.read(premiumStatusProvider).load();
    await tester.pump();
    return captured;
  }

  testWidgets(
    'review access active: PremiumAccess and the OR conversation gate both allow',
    (tester) async {
      final (container, _, _) = await buildContainer();
      final context = await pumpHost(tester, container);
      expect(PremiumAccess.isActive(context), isFalse);
      expect(CompanionOrConversationAccess.isAllowed(context), isFalse);

      final granted = await container
          .read(premiumStatusProvider)
          .activateReviewAccess('PLAY-REVIEW-1');
      expect(granted, isTrue);
      await tester.pump();

      expect(PremiumAccess.isActive(context), isTrue);
      expect(CompanionOrConversationAccess.isAllowed(context), isTrue);
      expect(CompanionOrConversationAccess.canCompose(context), isTrue);
      // Distinguishable — commerce state is untouched by review access.
      expect(
        CompanionOrConversationAccess.stateOf(context),
        isNot(PremiumEntitlementState.active),
      );
      container.dispose();
    },
  );

  testWidgets('real Premium active: OR conversation gate still allows', (
    tester,
  ) async {
    final (container, premium, _) = await buildContainer(
      storeConfigured: true,
    );
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'real-token',
      ),
    );
    await container.read(premiumStatusProvider).load();
    final context = await pumpHost(tester, container);

    expect(PremiumAccess.isActive(context), isTrue);
    expect(CompanionOrConversationAccess.isAllowed(context), isTrue);
    container.dispose();
  });

  testWidgets('neither real Premium nor review access: still paywalled', (
    tester,
  ) async {
    final (container, _, _) = await buildContainer();
    final context = await pumpHost(tester, container);

    expect(PremiumAccess.isActive(context), isFalse);
    expect(CompanionOrConversationAccess.isAllowed(context), isFalse);
    container.dispose();
  });

  testWidgets(
    'server-disabled review access stops granting after reconciliation',
    (tester) async {
      final (container, _, reviewService) = await buildContainer();
      final context = await pumpHost(tester, container);
      final status = container.read(premiumStatusProvider);
      await status.activateReviewAccess('PLAY-REVIEW-1');
      await tester.pump();
      expect(CompanionOrConversationAccess.isAllowed(context), isTrue);

      reviewService.validCode = null; // operator disables the code
      await status.refresh();
      await tester.pump();

      expect(PremiumAccess.isActive(context), isFalse);
      expect(CompanionOrConversationAccess.isAllowed(context), isFalse);
      container.dispose();
    },
  );

  test(
    'OrSessionResolver: premiumUnlocked lets review access compose without a fake active entitlement',
    () {
      final withoutAccess = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        premiumUnlocked: false,
      );
      expect(withoutAccess.canCompose, isFalse);

      final withReviewAccess = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        premiumUnlocked: true,
      );
      expect(withReviewAccess.canCompose, isTrue);

      // Omitting the param preserves prior (commerce-only) behavior.
      final omitted = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
      );
      expect(omitted.canCompose, isFalse);
    },
  );

  test(
    'a lingering commerce pending/restoring state never re-paywalls a valid '
    'review access grant (the actual reported bug)',
    () {
      for (final stuck in [
        PremiumEntitlementState.pending,
        PremiumEntitlementState.restoring,
      ]) {
        final withReviewAccess = OrSessionResolver.resolve(
          entitlement: stuck,
          link: CompanionLinkStatus.online,
          voiceUnavailable: false,
          chamberEmpty: false,
          premiumUnlocked: true,
        );
        expect(
          withReviewAccess.canCompose,
          isTrue,
          reason: 'review access must win over a stuck $stuck commerce state',
        );
        expect(withReviewAccess.showPaywallDock, isFalse);
        expect(withReviewAccess.showPreview, isFalse);
        expect(withReviewAccess.state, isNot(OrSessionState.purchasePending));

        // Real commerce pending/restoring, no review access: unchanged —
        // still shows the pending state honestly.
        final withoutAccess = OrSessionResolver.resolve(
          entitlement: stuck,
          link: CompanionLinkStatus.online,
          voiceUnavailable: false,
          chamberEmpty: false,
          premiumUnlocked: false,
        );
        expect(withoutAccess.canCompose, isFalse);
        expect(withoutAccess.state, OrSessionState.purchasePending);
      }
    },
  );

  testWidgets(
    'CompanionReferenceOrPaywall: premiumUnlocked shows the active state without a fake commerce entitlement',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompanionReferenceOrPaywall(
                entitlement: PremiumEntitlementState.inactive,
                premiumUnlocked: true,
                purchaseConfigured: false,
                onPurchase: () {},
                onRestore: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final cta = tester.widget<PremiumReferenceCta>(
        find.byType(PremiumReferenceCta),
      );
      expect(cta.isPremium, isTrue);
    },
  );

  Future<void> pumpOrPaywallHost(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CompanionReferenceOrPaywallHost(showHero: false),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'reported bug, end to end: review access active + store purchase '
    'unavailable => the store-unavailable paywall never renders in OR',
    (tester) async {
      // Default buildContainer() == UnavailablePremiumPurchase, exactly the
      // real-device state described ("store purchase is not open yet").
      final (container, _, _) = await buildContainer();
      await container.read(premiumStatusProvider).load();
      final granted = await container
          .read(premiumStatusProvider)
          .activateReviewAccess('PLAY-REVIEW-1');
      expect(granted, isTrue);
      expect(container.read(premiumStatusProvider).isPremium, isTrue);
      // Raw commerce entitlement stays honest and untouched by review access.
      expect(
        container.read(premiumStatusProvider).entitlement,
        PremiumEntitlementState.unavailable,
      );

      await pumpOrPaywallHost(tester, container);

      expect(find.text(PremiumCopy.ctaExplore), findsNothing);
      expect(find.text(PremiumCopy.ctaUnavailable), findsNothing);
      expect(find.text(PremiumCopy.ctaRetryStore), findsNothing);
      container.dispose();
    },
  );

  testWidgets(
    'reported bug, end to end: review access active + commerce entitlement '
    'stuck pending => the store-unavailable paywall never renders in OR',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();
      final premium = MockPremiumRepository(storage, secureStorage: secure);
      final users = MockUserRepository(storage);
      final reviewRepo = ReviewAccessRepository(storage, secureStorage: secure);
      final reviewService = _FakeReviewAccessService();
      await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
      await premium.savePurchaseCredentials(
        const PremiumPurchaseCredentials(
          platform: 'android',
          productId: 'app.oracly.premium.yearly',
          purchaseToken: 'stuck-token',
        ),
      );
      final service = PremiumService(
        premium,
        users,
        _ConfiguredPort(),
        _PendingVerifier(),
        reviewRepo,
        reviewService,
      );
      final container = ProviderContainer(
        overrides: [premiumServiceProvider.overrideWithValue(service)],
      );
      await container.read(premiumStatusProvider).load();
      expect(
        container.read(premiumStatusProvider).entitlement,
        PremiumEntitlementState.pending,
      );
      final granted = await container
          .read(premiumStatusProvider)
          .activateReviewAccess('PLAY-REVIEW-1');
      expect(granted, isTrue);
      expect(container.read(premiumStatusProvider).isPremium, isTrue);

      await pumpOrPaywallHost(tester, container);

      expect(find.text(PremiumCopy.ctaExplore), findsNothing);
      expect(find.text(PremiumCopy.ctaUnavailable), findsNothing);
      expect(find.text(PremiumCopy.ctaRetryStore), findsNothing);
      container.dispose();
    },
  );

  testWidgets(
    'without review access or real Premium, the store-unavailable paywall renders normally in OR',
    (tester) async {
      final (container, _, _) = await buildContainer();
      await container.read(premiumStatusProvider).load();
      expect(container.read(premiumStatusProvider).isPremium, isFalse);

      await pumpOrPaywallHost(tester, container);

      // Store is fully unavailable (not merely inactive), so the widget's
      // own canStartRestore rule legitimately hides the retry action —
      // title and body are the stable proof this paywall rendered at all.
      expect(find.text(PremiumCopy.ctaExplore), findsOneWidget);
      expect(find.text(PremiumCopy.ctaUnavailable), findsOneWidget);
      container.dispose();
    },
  );
}
