/// Phase 8 — production-faithful E2E world (test-only).
/// REAL PROVIDER CALLS = 0.
library;

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:oracly_new/features/tarot/services/tarot_reading_load_path.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_gem_authority.dart';
import '../narrative_history/tarot_4c_test_support.dart';
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_trace.dart';

/// Shared storage survives “module restart”; cache/AI/controller do not.
class TarotE2eWorld {
  TarotE2eWorld._(this.storage, this.authority, this.wallet, this.charge);

  final LocalStorage storage;
  final FakeGemAuthority authority;
  final GemWalletService wallet;
  final TarotReadingCharge charge;
  final trace = TarotE2eTrace();
  late Phase4cHarness harness;

  static Future<TarotE2eWorld> create({int gems = 100}) async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final authority = FakeGemAuthority(balance: gems);
    final wallet = authority.wallet(storage);
    await wallet.refresh();
    final world = TarotE2eWorld._(
      storage,
      authority,
      wallet,
      TarotReadingCharge(wallet, storage),
    );
    world.harness = Phase4cHarness(storage);
    world.trace.walletBefore = authority.balance;
    return world;
  }

  CountingInterpretationCache newCache() => CountingInterpretationCache();

  TarotInterpretationService interpretation(
    ScriptedNarrativeAi ai,
    CountingInterpretationCache cache,
  ) =>
      TarotInterpretationService(
        narrativeInterpreter: NarrativeTarotLiveInterpreter(
          ai: ai,
          historyLoader: harness.loader(),
          cache: cache,
          clock: () => DateTime.utc(2026, 9, 25, 16),
        ),
        allowLocalFallback: false,
      );

  TarotReadingController controller(TarotInterpretationService interp) =>
      TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(storage),
        interpretationService: interp,
      );

  /// Production-faithful load path (CASE A/B/C). Prefer over raw [complete].
  Future<AiReadingContent?> completePaid(
    ReadingSession session,
    TarotInterpretationService interp, {
    bool Function()? shouldCommit,
  }) {
    return TarotReadingLoadPath.resolve(
      session: session,
      charge: charge,
      completion: TarotReadingCompletion(
        charge: charge,
        interpretation: interp,
      ),
      generate: () => interp.generateContent(session, language: 'en'),
      shouldCommit: shouldCommit ?? () => true,
    );
  }

  /// Like [completePaid] but uses controller so provenance persists on session.
  Future<AiReadingContent?> completeViaController(
    TarotReadingController ctrl,
    TarotInterpretationService interp, {
    bool Function()? shouldCommit,
  }) {
    final session = ctrl.session!;
    return TarotReadingLoadPath.resolve(
      session: session,
      charge: charge,
      completion: TarotReadingCompletion(
        charge: charge,
        interpretation: interp,
      ),
      generate: () => ctrl.resolveInterpretationContent(),
      shouldCommit: shouldCommit ?? () => true,
    );
  }

  void captureSession(ReadingSession s) {
    trace.sessionId = s.id;
    trace.spread = s.spread.name;
    trace.shuffleSeed = s.shuffleSeed;
    trace.drawnCardIds
      ..clear()
      ..addAll(s.drawnCards.map((c) => c.card.id));
    trace.positionKeys
      ..clear()
      ..addAll(s.drawnCards.map((c) => c.positionKey ?? ''));
    trace.reversed
      ..clear()
      ..addAll(s.drawnCards.map((c) => c.isReversed));
    trace.interpretationFingerprint = s.interpretation;
    trace.activeSessionPresent = s.status == ReadingSessionStatus.inProgress;
  }

  void captureContent(AiReadingContent c) {
    trace.interpretationSource = c.interpretationSource.name;
    trace.deliveryKind = c.deliveryKind.name;
    trace.interpretationFingerprint = c.fullInterpretation;
  }

  void captureWallet() => trace.walletAfter = authority.balance;

  int get settlePosts =>
      authority.requests; // coarse; prefer charge.alreadyCharged checks
}
