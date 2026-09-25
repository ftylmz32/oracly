/// Phase 6F.1 — gem billing still after final quality only.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_completion.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_interpreter.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_gem_authority.dart';
import '../narrative_history/tarot_4c_test_support.dart';
import '../narrative_shadow/narrative_shadow_test_support.dart';
import 'phase6f_live_support.dart';

/// three_contrast sol call — ritual majors 1 / 6 / 11.
ReadingSession threeContrastSession({String id = 'bill_three'}) =>
    ReadingSession(
      id: id,
      deckId: 'classic',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(text: '', topic: null),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 24, 12),
      drawnCards: [
        TarotDrawnCard(
          card: ritualCard(1),
          positionIndex: 0,
          isReversed: false,
          positionKey: 'past',
        ),
        TarotDrawnCard(
          card: ritualCard(6),
          positionIndex: 1,
          isReversed: false,
          positionKey: 'present',
        ),
        TarotDrawnCard(
          card: ritualCard(11),
          positionIndex: 2,
          isReversed: false,
          positionKey: 'future',
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late GemWalletService wallet;
  late TarotReadingCharge charge;
  late FakeGemAuthority authority;
  late Phase4cHarness harness;
  late CountingInterpretationCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    authority = FakeGemAuthority(balance: 50);
    wallet = authority.wallet(storage);
    await wallet.refresh();
    charge = TarotReadingCharge(wallet, storage);
    harness = Phase4cHarness(storage);
    cache = CountingInterpretationCache();
  });

  TarotInterpretationService interpretation(ScriptedNarrativeAi ai) =>
      TarotInterpretationService(
        narrativeInterpreter: NarrativeTarotLiveInterpreter(
          ai: ai,
          historyLoader: harness.loader(),
          cache: cache,
          clock: () => DateTime.utc(2026, 9, 24, 19),
        ),
        allowLocalFallback: false,
      );

  Future<AiReadingContent?> completeEn(
    ScriptedNarrativeAi ai,
    ReadingSession session, {
    bool Function()? shouldCommit,
  }) {
    final interp = interpretation(ai);
    return TarotReadingCompletion(
      charge: charge,
      interpretation: interp,
    ).complete(
      session,
      load: () => interp.generateContent(session, language: 'en'),
      shouldCommit: shouldCommit,
    );
  }

  test('provider failure → markProviderOk 0, commit 0', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.failure(AiFailure.providerError()),
      AiOutcome.failure(AiFailure.providerError()),
    ]);
    final session = threeContrastSession(id: 'bill_fail');
    final before = wallet.balance;
    final result = await completeEn(ai, session);
    expect(result, isNull);
    expect(charge.alreadyCharged(session.id), isFalse);
    expect(wallet.balance, before);
    expect(cache.writes, isEmpty);
  });

  test('both quality fails → markProviderOk 0, commit 0', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured(callIndex: 3)),
      AiOutcome.success(qualityFailStructured(callIndex: 3)),
    ]);
    final session = threeContrastSession(id: 'bill_qfail');
    final before = wallet.balance;
    final result = await completeEn(ai, session);
    expect(result, isNull);
    expect(charge.alreadyCharged(session.id), isFalse);
    expect(wallet.balance, before);
    expect(cache.writes, isEmpty);
  });

  test('attempt1 quality fail + attempt2 pass → charge once', () async {
    final good = cloneSolThreeForEmptySession();
    good['synthesis'] = '${good['synthesis']} Second attempt presence.';
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(qualityFailStructured(callIndex: 3)),
      AiOutcome.success(good),
    ]);
    final session = threeContrastSession(id: 'bill_retry_ok');
    final before = wallet.balance;
    final result = await completeEn(ai, session);
    expect(result, isNotNull);
    expect(result!.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(ai.callCount, 2);
    expect(charge.alreadyCharged(session.id), isTrue);
    expect(wallet.balance, before - TarotEconomy.readingCost);
    expect(cache.writes, hasLength(1));
  });

  test('shouldCommit false → commit 0', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final session = threeContrastSession(id: 'bill_nocommit');
    final before = wallet.balance;
    final result = await completeEn(ai, session, shouldCommit: () => false);
    expect(result, isNull);
    expect(charge.alreadyCharged(session.id), isFalse);
    expect(wallet.balance, before);
  });

  test('safety → provider 0, charge 0', () async {
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolStructured(callIndex: 3)),
    ]);
    final session = ReadingSession(
      id: 'bill_safety',
      deckId: 'classic',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(
        text: 'Intihar etmeyi düşünüyorum',
        topic: null,
      ),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 24, 12),
      drawnCards: threeContrastSession().drawnCards,
    );
    final before = wallet.balance;
    final result = await completeEn(ai, session);
    expect(result, isNotNull);
    expect(result!.deliveryKind, TarotReadingDeliveryKind.safety);
    expect(ai.callCount, 0);
    expect(charge.alreadyCharged(session.id), isFalse);
    expect(wallet.balance, before);
    expect(cache.writes, isEmpty);
  });
}
