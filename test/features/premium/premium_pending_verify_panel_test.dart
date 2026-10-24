/// #44 — a paid store proof without a definitive verdict shows a clear,
/// accessible "checking your purchase" panel instead of plans and a buy
/// button. The only action re-verifies the saved proof on a direct tap:
/// it never buys or restores, runs once at a time, never runs under an
/// open store sheet, and never grants without an active verdict.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/legal/legal_copy.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_pending_verify_panel.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_plan_card.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/premium/providers/premium_entitlement_verifier_provider.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: PremiumStoreCatalog.monthlyId,
  purchaseToken: 'held-token',
  transactionId: 'held-txn',
);

/// Answers from a script; a [gate] holds the next answer until released.
class _Verifier implements PremiumEntitlementVerifier {
  _Verifier(this.results);
  final List<PremiumVerifyResult> results;
  Completer<void>? gate;
  int calls = 0;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    final result = results[calls.clamp(0, results.length - 1)];
    calls++;
    final g = gate;
    if (g != null) await g.future;
    return result;
  }
}

/// Priced store that counts every billing call; [sheet] keeps a purchase
/// or restore open like a store sheet the user has not answered yet.
class _Store implements PremiumPurchasePort {
  _Store(this.premium);
  final MockPremiumRepository premium;
  Completer<void>? sheet;
  int purchases = 0;
  int restores = 0;

  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {}
  @override
  String? priceLabel(PremiumPlanKind plan) => 'STORE-${plan.name}';

  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    purchases++;
    final s = sheet;
    if (s != null) await s.future;
    await premium.savePurchaseCredentials(_creds);
    return PremiumPurchaseResult.granted(plan, credentials: _creds);
  }

  @override
  Future<PremiumPurchaseResult> restore() async {
    restores++;
    final s = sheet;
    if (s != null) await s.future;
    return PremiumPurchaseResult.noneFound();
  }

  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

class _Fixture {
  _Fixture(this.storage, this.premium, this.verifier, this.store);
  final LocalStorage storage;
  final MockPremiumRepository premium;
  final _Verifier verifier;
  final _Store store;

  PremiumStatusController controller() => PremiumStatusController(
    PremiumService(premium, MockUserRepository(storage), store, verifier)
      ..forceReleaseMode = true,
  );
}

Future<_Fixture> _fixture(
  List<PremiumVerifyResult> results, {
  bool heldProof = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  final premium = MockPremiumRepository(
    storage,
    secureStorage: InMemorySecureStorage(),
  );
  if (heldProof) await premium.savePurchaseCredentials(_creds);
  return _Fixture(storage, premium, _Verifier(results), _Store(premium));
}

Future<void> _pumpScreen(WidgetTester tester, _Fixture f) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: f.storage,
      purchasePort: f.store,
      overrides: [
        premiumRepositoryProvider.overrideWithValue(f.premium),
        premiumEntitlementVerifierProvider.overrideWithValue(f.verifier),
      ],
      child: const MaterialApp(home: PremiumReferenceScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('controller status check', () {
    test('held proof loads as pending and grants nothing', () async {
      final f = await _fixture([PremiumVerifyResult.error('network')]);
      final c = f.controller();
      await c.load();
      expect(c.entitlement, PremiumEntitlementState.pending);
      expect(c.isPremium, isFalse);
      expect(c.storeTransactionInFlight, isFalse);
      expect(await f.premium.isPremiumActive(), isFalse);
    });

    test('check re-verifies the same proof and unlocks on an active verdict '
        'without buying or restoring', () async {
      final f = await _fixture([
        PremiumVerifyResult.error('network'),
        PremiumVerifyResult.active('subscription_active'),
      ]);
      final c = f.controller();
      await c.load();
      await c.checkPendingStatus();
      expect(c.entitlement, PremiumEntitlementState.active);
      expect(c.isPremium, isTrue);
      expect(f.verifier.calls, 2);
      expect(f.store.purchases, 0);
      expect(f.store.restores, 0);
    });

    test('a transient verdict keeps the pending hold and the proof', () async {
      final f = await _fixture([PremiumVerifyResult.error('network')]);
      final c = f.controller();
      await c.load();
      await c.checkPendingStatus();
      expect(c.entitlement, PremiumEntitlementState.pending);
      expect(c.isPremium, isFalse);
      expect(await f.premium.readPurchaseCredentials(), isNotNull);
      final retry = await c.purchase();
      expect(retry.granted, isFalse);
      expect(f.store.purchases, 0, reason: 'no second payment while held');
    });

    test('a definitive verdict releases the hold without a grant', () async {
      final f = await _fixture([
        PremiumVerifyResult.error('network'),
        PremiumVerifyResult.expired('subscription_expired'),
      ]);
      final c = f.controller();
      await c.load();
      await c.checkPendingStatus();
      expect(c.entitlement, PremiumEntitlementState.inactive);
      expect(c.isPremium, isFalse);
      expect(await f.premium.readPurchaseCredentials(), isNull);
    });

    test('repeat taps share one check', () async {
      final f = await _fixture([
        PremiumVerifyResult.error('network'),
        PremiumVerifyResult.error('network'),
      ]);
      final c = f.controller();
      await c.load();
      f.verifier.gate = Completer<void>();
      final first = c.checkPendingStatus();
      final second = c.checkPendingStatus();
      expect(c.checkingPendingStatus, isTrue);
      f.verifier.gate!.complete();
      await Future.wait([first, second]);
      expect(f.verifier.calls, 2, reason: 'load + exactly one check');
      expect(c.checkingPendingStatus, isFalse);
    });

    test('no check runs while the store sheet is still open', () async {
      final f = await _fixture(
        [PremiumVerifyResult.active('subscription_active')],
        heldProof: false,
      );
      final c = f.controller();
      await c.load();
      f.store.sheet = Completer<void>();
      final purchase = c.purchase();
      await Future<void>.delayed(Duration.zero);
      expect(c.entitlement, PremiumEntitlementState.pending);
      expect(c.storeTransactionInFlight, isTrue);
      final before = f.verifier.calls;
      await c.checkPendingStatus();
      expect(f.verifier.calls, before, reason: 'no reconcile under the sheet');
      f.store.sheet!.complete();
      await purchase;
      expect(c.storeTransactionInFlight, isFalse);
      expect(c.entitlement, PremiumEntitlementState.active);
      expect(f.store.purchases, 1);
    });
  });

  group('paywall panel', () {
    testWidgets('held proof shows the panel instead of plans or a buy button',
        (tester) async {
      final f = await _fixture([PremiumVerifyResult.error('network')]);
      await _pumpScreen(tester, f);

      expect(tester.takeException(), isNull);
      expect(find.byType(PremiumPendingVerifyPanel), findsOneWidget);
      expect(find.text(PremiumCopy.pendingVerifyTitle), findsOneWidget);
      expect(find.text(PremiumCopy.pendingVerifyBody), findsOneWidget);
      expect(find.text(PremiumCopy.pendingVerifyAccess), findsOneWidget);
      expect(find.text(PremiumCopy.pendingVerifyCheck), findsOneWidget);
      expect(find.byType(PremiumReferencePlanCard), findsNothing);
      expect(find.byType(OraclyGoldButton), findsNothing);
      expect(find.textContaining('STORE-'), findsNothing);
      expect(find.text(PremiumCopy.ctaRestore), findsNothing);
      expect(find.text(PremiumCopy.ctaBusy), findsNothing);
      // Nothing is on sale: no plan period, restore hint or plan jump.
      for (final kind in PremiumPlanKind.values) {
        expect(find.text(LegalCopy.planDisclosure(kind)), findsNothing);
      }
      expect(find.text(LegalCopy.restoreNote), findsNothing);
      expect(find.text(PremiumCopy.seePlans), findsNothing);
      expect(find.text(LegalCopy.storeBillingNote), findsOneWidget,
          reason: 'the neutral store billing note stays');
    });

    testWidgets('title is a heading and the panel announces changes',
        (tester) async {
      final handle = tester.ensureSemantics();
      final f = await _fixture([PremiumVerifyResult.error('network')]);
      await _pumpScreen(tester, f);
      // Screen readers only reach what is on screen.
      await tester.ensureVisible(find.byType(PremiumPendingVerifyPanel));
      await tester.pump();

      expect(
        find.ancestor(
          of: find.text(PremiumCopy.pendingVerifyTitle),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.header == true,
          ),
        ),
        findsOneWidget,
        reason: 'screen readers announce the status title as a heading',
      );
      expect(
        find.ancestor(
          of: find.text(PremiumCopy.pendingVerifyBody),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
        reason: 'TalkBack/VoiceOver hear status changes',
      );
      expect(
        tester.getSemantics(find.text(PremiumCopy.pendingVerifyCheck)),
        isSemantics(
          label: PremiumCopy.pendingVerifyCheck,
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
        reason: 'the check is its own focusable button',
      );
      expect(
        tester.getSemantics(find.text(PremiumCopy.pendingVerifyBody)),
        isSemantics(label: PremiumCopy.pendingVerifyBody, isButton: false),
        reason: 'body text is not merged into the button',
      );
      handle.dispose();
    });

    testWidgets('tap checks once, shows progress, then unlocks Premium',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final f = await _fixture([
        PremiumVerifyResult.error('network'),
        PremiumVerifyResult.active('subscription_active'),
      ]);
      await _pumpScreen(tester, f);
      f.verifier.gate = Completer<void>();

      await tester.ensureVisible(find.text(PremiumCopy.pendingVerifyCheck));
      await tester.pump();
      await tester.tap(find.text(PremiumCopy.pendingVerifyCheck));
      await tester.pump();
      expect(find.text(PremiumCopy.pendingVerifyChecking), findsOneWidget);
      expect(
        tester.getSemantics(find.text(PremiumCopy.pendingVerifyChecking)),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
        reason: 'screen readers hear the check as busy, not tappable',
      );
      await tester.tap(find.text(PremiumCopy.pendingVerifyChecking));
      await tester.pump();

      f.verifier.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(f.verifier.calls, 2, reason: 'load + one check, not two');
      expect(find.byType(PremiumPendingVerifyPanel), findsNothing);
      expect(find.text(PremiumCopy.membershipOpen), findsOneWidget);
      expect(f.store.purchases, 0);
      expect(f.store.restores, 0);
      semantics.dispose();
    });

    testWidgets('restoring is not shown as a pending purchase',
        (tester) async {
      final f = await _fixture(
        [PremiumVerifyResult.active('ok')],
        heldProof: false,
      );
      await _pumpScreen(tester, f);
      f.store.sheet = Completer<void>();
      await tester.ensureVisible(find.text(PremiumCopy.ctaRestore));
      await tester.pump();
      await tester.tap(find.text(PremiumCopy.ctaRestore));
      await tester.pump();

      expect(f.store.restores, 1, reason: 'the restore sheet is really open');
      expect(find.byType(PremiumPendingVerifyPanel), findsNothing);
      expect(find.text(PremiumCopy.pendingVerifyTitle), findsNothing);
      f.store.sheet!.complete();
      await tester.pump(const Duration(milliseconds: 80));
    });
  });
}
