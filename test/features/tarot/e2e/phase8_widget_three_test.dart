/// Phase 8 — flagship 3-card: real TarotTableScene + ReadingScreen.
/// REAL PROVIDER CALLS = 0. Test harness only — no production changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_screen.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/ritual/ritual_settle_outcome.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_intent_catalogue.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_scene.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_controller.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_settle.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_gem_authority.dart';
import '../narrative_history/tarot_4c_test_support.dart';
import '../narrative_live/phase6f_live_support.dart';
import 'phase8_adaptive_sol_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'flagship threeCard table→draw×3→settle→ReadingScreen Narrative',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      OraclyL10n.bind('en');
      const viewport = Size(390, 844);
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final authority = FakeGemAuthority(balance: 100);
      final wallet = authority.wallet(storage);
      await wallet.refresh();
      final walletCtrl = GemWalletController(wallet);
      await walletCtrl.acceptAuthoritativeBalance(100);
      final ai = Phase8AdaptiveSolThreeAi();
      final interp = TarotInterpretationService(
        narrativeInterpreter: NarrativeTarotLiveInterpreter(
          ai: ai,
          historyLoader: Phase4cHarness(storage).loader(),
          cache: CountingInterpretationCache(),
          clock: () => DateTime.utc(2026, 9, 25, 16),
        ),
        allowLocalFallback: false,
      );
      final reading = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(storage),
        interpretationService: interp,
      );
      final flow = TarotFlowController();
      final ritual = TarotRitualController();
      final overrides = [
        localStorageProvider.overrideWithValue(storage),
        gemWalletServiceProvider.overrideWithValue(wallet),
        gemWalletProvider.overrideWith((ref) => walletCtrl),
      ];
      Widget wrap(Widget child) => ProviderScope(
            overrides: overrides,
            child: MediaQuery(
              data: const MediaQueryData(
                size: viewport,
                disableAnimations: true,
              ),
              child: TarotScope(flow: flow, reading: reading, child: child),
            ),
          );

      await tester.pumpWidget(
        wrap(const MaterialApp(home: TarotTableScene())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(TableIntentCatalogue.title('love')).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Crossroads'), findsNothing);
      await tester.tap(
        find.text(OraclyL10n.t('tarot.spread.threeCard.compact')),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (reading.session == null) {
        flow.captureIntention(const TarotIntention(text: '', topic: 'love'));
        flow.selectSpread(TarotSpreadType.threeCard);
        await reading.beginSession(
          spread: TarotSpreadType.threeCard,
          deckId: 'classic',
        );
      }
      final sid = reading.session!.id;
      if (reading.session!.flowStep.index <
          ReadingFlowStep.cardSelection.index) {
        await reading.advanceToShuffle();
        await reading.performShuffle();
        await reading.finishShuffle();
      }
      flow.selectDrawMode(TarotDrawMode.manual);
      ritual.domainShuffleDone = true;
      ritual.setVisual(ritual.visual.copyWith(stage: TarotRitualStage.draw));

      late BuildContext ritualContext;
      await tester.pumpWidget(
        wrap(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  ritualContext = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        expect(await ritual.commitDraw(ritualContext), isTrue);
        final o = await ritual.settleAfterReveal(ritualContext);
        expect(
          o,
          i < 2
              ? RitualSettleOutcome.continueDraw
              : RitualSettleOutcome.readingReady,
        );
        await tester.pump();
      }
      expect(reading.session!.drawnCards, hasLength(3));
      expect(
        reading.session!.drawnCards.map((c) => c.card.id).toSet(),
        hasLength(3),
      );

      await tester.pumpWidget(
        wrap(const MaterialApp(home: ReadingScreen())),
      );
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (find.byType(ReadingPremiumBody).evaluate().isNotEmpty) break;
      }
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(ai.callCount, 1);
      expect(authority.balance, 80);
      expect(reading.session!.id, sid);
      ritual.dispose();
      reading.dispose();
      flow.dispose();
    },
  );
}
