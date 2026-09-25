/// Phase 9 — TarotNavigator route attacks (no/partial/paid session).
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_navigator.dart';
import 'package:oracly_new/features/tarot/shared/constants/tarot_routes.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpRoute(
    WidgetTester tester, {
    required TarotE2eWorld world,
    required String route,
    ReadingSession? session,
  }) async {
    OraclyL10n.bind('en');
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final reading = world.controller(interp);
    if (session != null) await reading.updateSession(session);
    final flow = TarotFlowController();
    final walletCtrl = GemWalletController(world.wallet);
    await walletCtrl.acceptAuthoritativeBalance(world.authority.balance);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(world.storage),
          gemWalletServiceProvider.overrideWithValue(world.wallet),
          gemWalletProvider.overrideWith((ref) => walletCtrl),
        ],
        child: TarotScope(
          flow: flow,
          reading: reading,
          child: MaterialApp(
            initialRoute: route,
            onGenerateRoute: TarotNavigator.onGenerateRoute,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    reading.dispose();
  }

  testWidgets('intention/spread/reading — no session no crash', (tester) async {
    final world = await TarotE2eWorld.create();
    for (final route in [
      TarotRoutes.intention,
      TarotRoutes.spreadSelection,
      TarotRoutes.reading,
    ]) {
      await pumpRoute(tester, world: world, route: route);
    }
  });

  testWidgets('partial draw on reading — no free paid result', (tester) async {
    final world = await TarotE2eWorld.create();
    final partial = threeContrastSession(id: 'p9_nav_partial').copyWith(
      status: ReadingSessionStatus.inProgress,
      flowStep: ReadingFlowStep.reveal,
      drawnCards: [threeContrastSession().drawnCards.first],
    );
    await pumpRoute(
      tester,
      world: world,
      route: TarotRoutes.reading,
      session: partial,
    );
    expect(world.charge.alreadyCharged(partial.id), isFalse);
  });

  testWidgets('paid session reading route — no crash, still charged',
      (tester) async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_nav_paid');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    await world.completeViaController(ctrl, interp);
    await ctrl.flush();
    final paid = ctrl.session!;
    ctrl.dispose();
    await pumpRoute(
      tester,
      world: world,
      route: TarotRoutes.reading,
      session: paid,
    );
    expect(world.charge.alreadyCharged(session.id), isTrue);
  });
}
