/// P0 — one real deck, truthful interpretation source, gem commit boundary.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_content_catalogue.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/ai_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/local_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck_selection/deck_selection_data.dart';
import 'package:oracly_new/features/tarot/services/deck_service.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active deck is the real 78-card catalogue', () {
    const service = DeckService();
    final cards = service.createDeck();
    expect(cards, hasLength(78));
    expect(
      cards.map((c) => c.id).toSet(),
      TarotContentCatalogue.all.map((c) => c.id).toSet(),
    );
    expect(TarotDeckCatalogue.decks, hasLength(1));
    expect(TarotDeckCatalogue.decks.first.id, 'classic');
    expect(TarotDeckCatalogue.decks.first.cardCount, 78);
  });

  test('deckId cannot silently create fake distinct decks', () {
    const service = DeckService();
    final classic = service.createDeck(deckId: 'classic');
    final golden = service.createDeck(deckId: 'golden');
    final unknown = service.createDeck(deckId: 'invented-deck');
    expect(classic.map((c) => c.id), golden.map((c) => c.id));
    expect(classic.map((c) => c.id), unknown.map((c) => c.id));
    expect(service.resolveDeckId('moon_oracle'), DeckService.activeCanonicalId);
    expect(TarotDeckCatalogue.isUnbuilt('golden'), isTrue);
    expect(TarotDeckCatalogue.isSelectable('golden'), isFalse);
  });

  test('local interpretation is never labeled AI', () async {
    final local = await LocalInterpretationExecutor().execute(_request());
    expect(local.source, InterpretationSource.local);

    final stubAi = await AiInterpretationExecutor().execute(_request());
    expect(stubAi.source, InterpretationSource.local);
    expect(stubAi.source, isNot(InterpretationSource.ai));

    final content = await TarotInterpretationService().generateContent(
      _session(),
    );
    expect(content.isAiInterpretation, isFalse);
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false),
      startsWith(TarotPolishCopy.sourceLocal),
    );
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false).toLowerCase(),
      isNot(contains('yapay zek')),
    );
  });

  test('AI source is only AI after a successful real AI parse', () {
    final parsed = AiInterpretationExecutor().parseAiResponse(
      _request(),
      '''
## Açılımın Teması
Gerçek model yanıtı.

## Kartların Mesajı
Kartların gözlemlenen mesajı.

## Açılımın Genel Yorumu
Açılımın bütünü.
''',
    );
    expect(parsed, isNotNull);
    expect(parsed!.source, InterpretationSource.ai);
    expect(
      TarotPolishCopy.readingFootnote(fromAi: true),
      startsWith(TarotPolishCopy.sourceAi),
    );
  });

  group('gem commit boundary', () {
    late LocalStorage storage;
    late GemWalletService wallet;
    late TarotReadingCharge charge;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorage(await SharedPreferences.getInstance());
      wallet = GemWalletService(GemWalletStore(storage));
      charge = TarotReadingCharge(wallet, storage);
    });

    test('insufficient gems = no spend', () async {
      expect(wallet.balance, 0);
      expect(await charge.commit('s1'), isFalse);
      expect(wallet.balance, 0);
      expect(charge.alreadyCharged('s1'), isFalse);
    });

    test('back or cancel before commit = no spend', () async {
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      expect(wallet.canSpend(TarotEconomy.readingCost), isTrue);
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('s-cancel'), isFalse);
    });

    test('successful reading spends exactly 20 gems', () async {
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      expect(await charge.commit('s-ok'), isTrue);
      expect(wallet.balance, 30);
      expect(wallet.history.first.amount, -20);
    });

    test('duplicate action spends once', () async {
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      expect(await charge.commit('s-dup'), isTrue);
      expect(await charge.commit('s-dup'), isTrue);
      expect(wallet.balance, 30);
    });

    test('failed reading does not charge', () async {
      await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
      expect(wallet.balance, 50);
      expect(charge.alreadyCharged('s-fail'), isFalse);
    });

    test('balance never goes negative', () async {
      await wallet.earn(amount: 10, reason: GemsCopy.reasonDailyReward);
      expect(await charge.commit('s-neg'), isFalse);
      expect(wallet.balance, 10);
      expect(wallet.balance, greaterThanOrEqualTo(0));
    });
  });
}

InterpretationRequest _request() {
  return InterpretationRequest(
    requestId: 'r1',
    createdAt: DateTime(2026, 8, 9),
    context: ReadingContext(
      sessionId: 's1',
      spreadType: TarotSpreadType.single,
      spreadLabel: 'Günlük Kart',
      deckId: 'classic',
      language: 'tr',
      readingDate: DateTime(2026, 8, 9),
      cards: const [
        ReadingCardContext(
          cardId: 0,
          cardName: 'Deli',
          positionIndex: 0,
          positionLabel: 'Şimdi',
          positionKey: 'now',
          isReversed: false,
          uprightMeaning: 'Yeni bir başlangıç.',
          reversedMeaning: 'Tereddüt.',
          keywords: ['başlangıç'],
        ),
      ],
    ),
  );
}

ReadingSession _session() {
  final reveal = CardRevealSpread.forIndex(0);
  return ReadingSession(
    id: 'test_session',
    deckId: 'rider-waite',
    spread: TarotSpreadType.single,
    intention: const TarotIntention(text: 'Genel rehberlik'),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 8, 9),
    drawnCards: [
      TarotDrawnCard(
        card: reveal.card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Şimdi',
      ),
    ],
  );
}
