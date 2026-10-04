/// WAVE 1.7 — combined revenue-integrity gate for the Wave 1 fixes.
/// Covers the gaps not already proven by the focused Wave 1 suites:
///  * verified-Premium preservation is limited to exactly the two
///    verification-unavailable reasons; every definitive store verdict
///    still demotes, and definitive verdicts still advance freshness;
///  * Premium and Tarot/Gem recovery never touch each other's state;
///  * an account switch removes Premium evidence AND the Tarot payment
///    record that enables same-reading settle recovery.
/// REAL PROVIDER / STORE CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/premium_entitlement_reconciler.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/data/paid_ai_operation_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_gateway.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_id.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/premium_store_catalog.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:oracly_new/features/tarot/services/tarot_reading_load_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_gem_authority.dart';
import '../../support/test_path_provider.dart';
import '../tarot/narrative_history/tarot_4c_test_support.dart';
import '../tarot/narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../tarot/narrative_live/phase6f_live_support.dart';

const _creds = PremiumPurchaseCredentials(
  platform: 'android',
  productId: PremiumStoreCatalog.monthlyId,
  purchaseToken: 'wave17-token',
  transactionId: 'wave17-txn',
);

class _Verifier implements PremiumEntitlementVerifier {
  _Verifier(this.result);
  PremiumVerifyResult result;
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
    calls++;
    return result;
  }
}

class _NoopPort implements PremiumPurchasePort {
  int purchases = 0;
  @override
  bool get isConfigured => true;
  @override
  bool get canAttemptRestore => true;
  @override
  Future<void> prepare() async {}
  @override
  String? priceLabel(PremiumPlanKind plan) => null;
  @override
  Future<PremiumPurchaseResult> purchase(PremiumPlanKind plan) async {
    purchases++;
    return PremiumPurchaseResult.cancelled();
  }

  @override
  Future<PremiumPurchaseResult> restore() async =>
      PremiumPurchaseResult.noneFound();
  @override
  Future<PremiumPurchaseResult?> consumeUnsolicitedGrant() async => null;
}

/// Server processes every request; one settle response can be lost.
class _Transport {
  _Transport(this.server);
  final FakeGemAuthority server;
  bool loseNextSettleResponse = false;
  int settlePosts = 0;

  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    final wire = await server.send(method, path, body);
    if (path.endsWith('/settle')) {
      settlePosts++;
      if (loseNextSettleResponse) {
        loseNextSettleResponse = false;
        return null;
      }
    }
    return wire;
  }
}

/// One device: shared prefs + secure storage for both revenue systems.
class _Device {
  _Device._(this.storage, this.secure);
  final LocalStorage storage;
  final InMemorySecureStorage secure;

  static Future<_Device> create({String owner = 'user-a'}) async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    final storage = LocalStorage(await SharedPreferences.getInstance());
    await storage.setString(UserLocalDataIsolation.ownerKey, owner);
    return _Device._(storage, InMemorySecureStorage());
  }

  MockPremiumRepository premiumFor(String owner) => MockPremiumRepository(
        storage,
        secureStorage: secure,
        ownerAccessAllowed: () =>
            storage.getString(UserLocalDataIsolation.ownerKey) == owner,
      );

  Future<MockPremiumRepository> verifiedSubscriber(String owner) async {
    final premium = premiumFor(owner);
    await premium.savePurchaseCredentials(_creds);
    await premium.activatePlan(PremiumPlanKind.monthly, authoritative: true);
    return premium;
  }

  Future<({FakeGemAuthority server, _Transport transport, GemWalletService wallet, TarotReadingCharge charge})>
      gems(int balance) async {
    final server = FakeGemAuthority(balance: balance);
    final transport = _Transport(server);
    final wallet = GemWalletService(
      GemWalletStore(storage),
      gateway: GemWalletGateway(transport.send),
    );
    await wallet.refresh();
    return (
      server: server,
      transport: transport,
      wallet: wallet,
      charge: TarotReadingCharge(wallet, storage),
    );
  }

  Future<AiReadingContent?> openTarot(
    ReadingSession session,
    TarotReadingCharge charge,
  ) {
    final interp = TarotInterpretationService(
      narrativeInterpreter: NarrativeTarotLiveInterpreter(
        ai: ScriptedNarrativeAi([
          for (var i = 0; i < 3; i++)
            AiOutcome.success(cloneSolThreeForEmptySession()),
        ]),
        historyLoader: Phase4cHarness(storage).loader(),
        cache: CountingInterpretationCache(),
        clock: () => DateTime.utc(2026, 10, 4, 21),
      ),
      allowLocalFallback: false,
    );
    return TarotReadingLoadPath.resolve(
      session: session,
      charge: charge,
      completion: TarotReadingCompletion(charge: charge, interpretation: interp),
      generate: () => interp.generateContent(session, language: 'en'),
      shouldCommit: () => true,
    );
  }

  String? paidOpsRaw() =>
      storage.getStringList(PaidAiOperationStore.key)?.join('|');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Premium preservation scope is exactly the two unavailable reasons',
      () {
    for (final result in [
      PremiumVerifyResult.unverified('purchase_bound_to_other_account'),
      PremiumVerifyResult.unverified('product_mismatch'),
      PremiumVerifyResult.unverified('jws_invalid'),
      PremiumVerifyResult.unverified('verification_failed'),
      PremiumVerifyResult.unverified('unknown_status'),
      PremiumVerifyResult.inactive('not_owned'),
    ]) {
      test('verified subscriber + ${result.status.name}/${result.reason} '
          'is demoted definitively (no free Premium)', () async {
        final device = await _Device.create();
        final premium = await device.verifiedSubscriber('user-a');
        final snap = await PremiumEntitlementReconciler(
          premium: premium,
          purchaseConfigured: true,
          verifier: _Verifier(result),
          forceReleaseMode: true,
        ).reconcile();

        expect(snap.entitlement, isNot(PremiumEntitlementState.active));
        expect(snap.definitive, isTrue);
        expect(await premium.isPremiumActive(), isFalse);
        expect(premium.wasAuthoritativelyVerified, isFalse);
      });
    }

    test('a definitive expired verdict still advances normal freshness',
        () async {
      final device = await _Device.create();
      final premium = await device.verifiedSubscriber('user-a');
      final verifier = _Verifier(PremiumVerifyResult.expired('expired'));
      final port = _NoopPort();
      final controller = PremiumStatusController(
        PremiumService(premium, MockUserRepository(device.storage), port,
            verifier)
          ..forceReleaseMode = true,
      );

      await controller.load();
      await controller.ensureFresh();

      expect(controller.isPremium, isFalse);
      expect(controller.isFresh, isTrue);
      expect(controller.lastDefinitiveReconciledAt, isNotNull);
      expect(verifier.calls, 1, reason: 'fresh definitive verdict is trusted');
      expect(port.purchases, 0, reason: 'recovery never starts a purchase');
    });
  });

  group('cross-system: Premium and Tarot/Gem recovery are independent', () {
    test('Premium refresh (unavailable or definitive) never calls the gem '
        'server nor alters wallet / payment records', () async {
      final device = await _Device.create();
      final premium = await device.verifiedSubscriber('user-a');
      final g = await device.gems(40);
      final session = threeContrastSession(id: 'wave17_cross_a');
      expect(await device.openTarot(session, g.charge), isNotNull);
      final requestsBefore = g.server.requests;
      final opsBefore = device.paidOpsRaw();
      final balanceBefore = g.wallet.balance;

      for (final result in [
        PremiumVerifyResult.unverified('auth_required'),
        PremiumVerifyResult.unverified('provider_not_configured'),
        PremiumVerifyResult.expired('expired'),
      ]) {
        await PremiumEntitlementReconciler(
          premium: premium,
          purchaseConfigured: true,
          verifier: _Verifier(result),
          forceReleaseMode: true,
        ).reconcile();
      }

      expect(g.server.requests, requestsBefore);
      expect(device.paidOpsRaw(), opsBefore);
      expect(g.wallet.balance, balanceBefore);
      expect(g.server.balance, 20);
    });

    test('Tarot lost-settle recovery never touches Premium state or the '
        'Premium verifier', () async {
      final device = await _Device.create();
      final premium = await device.verifiedSubscriber('user-a');
      final verifier = _Verifier(PremiumVerifyResult.active('ok'));
      final g = await device.gems(20);
      final session = threeContrastSession(id: 'wave17_cross_b');

      g.transport.loseNextSettleResponse = true;
      expect(await device.openTarot(session, g.charge), isNull);
      final recovered = await device.openTarot(session, g.charge);

      expect(recovered, isNotNull);
      expect(g.server.balance, 0);
      expect(g.transport.settlePosts, 2);
      expect(verifier.calls, 0);
      expect(await premium.isPremiumActive(), isTrue);
      expect(premium.wasAuthoritativelyVerified, isTrue);
      expect(await premium.readPurchaseCredentials(), isNotNull);
    });
  });

  test('account switch wipes Premium evidence AND the Tarot payment record '
      'together; user-b can neither inherit Premium nor recover user-a\'s '
      'reading', () async {
    await installTestPathProvider('oracly-wave17-switch-');
    final device = await _Device.create();
    await device.verifiedSubscriber('user-a');
    final a = await device.gems(20);
    final session = threeContrastSession(id: 'wave17_switch');
    a.transport.loseNextSettleResponse = true;
    expect(await device.openTarot(session, a.charge), isNull);
    final opId = PaidAiOperationId.fromExisting('tarot', session.id);
    expect(PaidAiOperationStore(device.storage).byId(opId), isNotNull,
        reason: 'user-a holds a recoverable payment record');

    await UserLocalDataIsolation(device.storage, secureStorage: device.secure)
        .onSignedIn('user-b');

    expect(device.storage.getString(UserLocalDataIsolation.ownerKey), 'user-b');
    expect(PaidAiOperationStore(device.storage).byId(opId), isNull);
    final asB = device.premiumFor('user-b');
    expect(await asB.isPremiumActive(), isFalse);
    expect(asB.wasAuthoritativelyVerified, isFalse);
    expect(await asB.readPurchaseCredentials(), isNull);

    final b = await device.gems(0);
    expect(await device.openTarot(session, b.charge), isNull);
    expect(b.transport.settlePosts, 0,
        reason: 'no record → no recovery attempt for user-b');
    expect(b.server.balance, 0);
    expect(a.server.balance, 0, reason: 'user-a still charged exactly once');
  });
}
