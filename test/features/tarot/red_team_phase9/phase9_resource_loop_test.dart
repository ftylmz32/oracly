/// Phase 9 — ReadingScreen pump/dispose loop (no setState-after-dispose).
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
import 'package:oracly_new/features/tarot/presentation/screens/reading_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pump ReadingScreen / dispose loop 5× — no crash', (tester) async {
    OraclyL10n.bind('en');
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final reading = world.controller(interp);
    await reading.updateSession(
      threeContrastSession(id: 'p9_res_loop').copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
        interpretation: '## Summary\nseeded body',
        interpretationResultMode: 'narrativeV2',
        interpretationSource: 'ai',
        interpretationDeliveryKind: 'interpretation',
      ),
    );
    await world.charge.commit('p9_res_loop', spread: reading.session!.spread);
    final flow = TarotFlowController();

    for (var i = 0; i < 5; i++) {
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
            child: const MaterialApp(home: ReadingScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    reading.dispose();
  });
}
