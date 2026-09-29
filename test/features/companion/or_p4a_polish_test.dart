/// P4A — OR cold-open paywall, conversation lapse, free menu gate.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_providers.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_composer_dock.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_conversation_guard.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_premium_dock.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_result.dart';
import 'package:oracly_new/features/premium/models/premium_verify_result.dart';
import 'package:oracly_new/features/premium/providers/premium_providers.dart';
import 'package:oracly_new/features/premium/services/premium_entitlement_verifier.dart';
import 'package:oracly_new/features/premium/services/premium_purchase_port.dart';
import 'package:oracly_new/features/premium/services/unavailable_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _HeldPremium extends PremiumStatusController {
  _HeldPremium(super.service);

  final gate = Completer<void>();

  @override
  Future<void> load() async {
    await gate.future;
    await super.load();
  }
}

class _FlipVerifier implements PremiumEntitlementVerifier {
  bool active = true;

  @override
  bool get isRemoteVerifierConfigured => true;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async =>
      active ? PremiumVerifyResult.active() : PremiumVerifyResult.expired();
}

class _StorePort implements PremiumPurchasePort {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<LocalStorage> storage() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorage.open();
  }

  Future<
    ({
      LocalStorage store,
      MockPremiumRepository repo,
      PremiumService service,
      _FlipVerifier verifier,
    })
  >
  activeMembership() async {
    final store = await storage();
    final secure = InMemorySecureStorage();
    final repo = MockPremiumRepository(store, secureStorage: secure);
    await repo.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await repo.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'app.oracly.premium.yearly',
        purchaseToken: 'token',
      ),
    );
    final verifier = _FlipVerifier();
    final service = PremiumService(
      repo,
      MockUserRepository(store),
      _StorePort(),
      verifier,
    );
    return (store: store, repo: repo, service: service, verifier: verifier);
  }

  PremiumService inactiveService(LocalStorage storage) {
    return PremiumService(
      MockPremiumRepository(storage),
      MockUserRepository(storage),
      const UnavailablePremiumPurchase(),
    );
  }

  Future<void> pumpOr(
    WidgetTester tester, {
    required PremiumStatusController premium,
    required LocalStorage store,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(store),
          premiumStatusProvider.overrideWith((ref) => premium),
          oraclyAiServiceProvider.overrideWithValue(
            const UnconfiguredOraclyAiService(allowsLocalFallback: true),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: const CompanionReferenceScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('unknown entitlement is neither a paywall nor a composer', () {
    for (final empty in [true, false]) {
      final session = OrSessionResolver.resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.online,
        voiceUnavailable: false,
        entitlementKnown: false,
        chamberEmpty: empty,
        premiumUnlocked: true,
      );
      expect(session.showPreview, isFalse);
      expect(session.showPaywallDock, isFalse);
      expect(session.canCompose, isFalse);
      expect(session.canUseMic, isFalse);
    }
  });

  testWidgets('a held Premium read does not flash the free chamber', (
    tester,
  ) async {
    final membership = await activeMembership();
    final held = _HeldPremium(membership.service);
    await pumpOr(tester, premium: held, store: membership.store);

    expect(find.text(CompanionCopy.orPremiumLead), findsNothing);
    expect(find.byType(CompanionReferenceOrPremiumDock), findsNothing);
    expect(find.byType(CompanionReferenceComposerDock), findsNothing);

    held.gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(held.loaded, isTrue);
    expect(held.isPremium, isTrue);
    expect(find.text(CompanionCopy.orPremiumLead), findsNothing);
    expect(find.byType(CompanionReferenceComposerDock), findsOneWidget);
  });

  testWidgets('a held read that finishes inactive shows the free preview', (
    tester,
  ) async {
    final store = await storage();
    final held = _HeldPremium(inactiveService(store));
    await pumpOr(
      tester,
      premium: held,
      store: store,
      size: const Size(320, 568),
    );
    expect(find.text(CompanionCopy.orPremiumLead), findsNothing);

    held.gate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(held.loaded, isTrue);
    expect(held.isPremium, isFalse);
    expect(find.text(CompanionCopy.orPremiumLead), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow and large text keep the quiet open and the free preview',
    (tester) async {
      for (final size in const [
        Size(320, 568),
        Size(360, 640),
        Size(390, 844),
      ]) {
        final store = await storage();
        final held = _HeldPremium(inactiveService(store));
        await pumpOr(tester, premium: held, store: store, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text(CompanionCopy.orPremiumLead), findsNothing);
        held.gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final store = await storage();
      final held = _HeldPremium(inactiveService(store));
      await pumpOr(
        tester,
        premium: held,
        store: store,
        size: const Size(360, 640),
        textScale: 1.4,
      );
      held.gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(CompanionCopy.orPremiumLead), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Premium lapse demotes Conversation once and leaves text alone', (
    tester,
  ) async {
    final membership = await activeMembership();
    final status = PremiumStatusController(membership.service);
    await status.load();
    expect(status.isPremium, isTrue);
    OraclyTtsGate.engine = null;
    addTearDown(() => OraclyTtsGate.engine = null);
    var mode = OrChatOutputMode.text;
    final output = CompanionOutputController(
      persistMode: (next) async => mode = next,
      readMode: () => mode,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(membership.store),
          premiumStatusProvider.overrideWith((ref) => status),
          companionOutputControllerProvider.overrideWith((ref) => output),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CompanionReferenceConversationGuard(child: SizedBox()),
          ),
        ),
      ),
    );
    await tester.pump();
    await output.setMode(OrChatOutputMode.conversation);
    await tester.pump();
    expect(output.isConversation, isTrue);

    await membership.repo.clearLocalPremiumAccess();
    membership.verifier.active = false;
    await status.forceReconcile();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(status.isPremium, isFalse);
    expect(output.mode, OrChatOutputMode.voice);
    expect(find.text(CompanionCopy.voiceConversationDemoted), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(CompanionReferenceConversationGuard)),
    ).clearSnackBars();
    await tester.pump();
    expect(find.text(CompanionCopy.voiceConversationDemoted), findsNothing);

    await status.forceReconcile();
    await tester.pump();
    expect(output.mode, OrChatOutputMode.voice);
    expect(find.text(CompanionCopy.voiceConversationDemoted), findsNothing);

    await output.setMode(OrChatOutputMode.text);
    await tester.pump();
    await status.forceReconcile();
    await tester.pump();
    expect(output.mode, OrChatOutputMode.text);
    expect(find.text(CompanionCopy.voiceConversationDemoted), findsNothing);
  });

  testWidgets('a free menu tap does not select Conversation', (tester) async {
    final store = await storage();
    final status = PremiumStatusController(inactiveService(store));
    await status.load();
    await pumpOr(tester, premium: status, store: store);
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CompanionCopy.outputConversation));
    await tester.pumpAndSettle();

    final output = ProviderScope.containerOf(
      tester.element(find.byType(CompanionReferenceScreen)),
    ).read(companionOutputControllerProvider);
    expect(output.mode, OrChatOutputMode.text);
    expect(
      find.text(CompanionCopy.voiceConversationPreviewTitle),
      findsOneWidget,
    );
    expect(find.text(CompanionCopy.voiceConversationDemoted), findsNothing);
  });

  test('failure copy stays on the existing user-facing lines', () {
    OraclyL10n.bind('en');
    final offline = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.offline,
      voiceUnavailable: false,
      lastFailure: AiFailureKind.network,
      premiumUnlocked: true,
    );
    expect(offline.statusLine, CompanionCopy.offline);
    expect(offline.canRetry, isTrue);
    final save = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.online,
      voiceUnavailable: false,
      lastFailure: AiFailureKind.localPersistence,
      premiumUnlocked: true,
    );
    expect(save.statusLine, CompanionCopy.saveFailed);
    expect(save.canRetry, isTrue);
    expect(save.statusLine, isNot(contains('HTTP')));
  });
}
