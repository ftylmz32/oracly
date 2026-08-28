/// TAROT V2 — start copy, optional intention, result, gems, history, OR.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/insights/services/reflective_card_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_reading_copy.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/epic031/tarot_epic031_page.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/services/tarot_interpretation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

ReadingCardContext _card({
  required int id,
  required String name,
  required int index,
  required String label,
  required bool reversed,
  required String upright,
  required String reversedMeaning,
}) {
  return ReadingCardContext(
    cardId: id,
    cardName: name,
    positionIndex: index,
    positionLabel: label,
    positionKey: label.toLowerCase(),
    isReversed: reversed,
    uprightMeaning: upright,
    reversedMeaning: reversedMeaning,
    keywords: const ['odak'],
  );
}

ReadingContext _context({String? question}) {
  return ReadingContext(
    sessionId: 'v2',
    spreadType: TarotSpreadType.threeCard,
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    language: 'tr',
    readingDate: DateTime(2026, 8, 9),
    userQuestion: question,
    readingTheme: 'love',
    cards: [
      _card(
        id: 0,
        name: 'The Fool',
        index: 0,
        label: 'Geçmiş',
        reversed: false,
        upright: 'Yeni bir başlangıç.',
        reversedMeaning: 'Tereddüt.',
      ),
      _card(
        id: 1,
        name: 'The Magician',
        index: 1,
        label: 'Şimdi',
        reversed: true,
        upright: 'Yaratıcı güç.',
        reversedMeaning: 'Dağınık niyet.',
      ),
      _card(
        id: 2,
        name: 'The High Priestess',
        index: 2,
        label: 'Olası yön',
        reversed: false,
        upright: 'İç ses.',
        reversedMeaning: 'Gizli kalmış bilgi.',
      ),
    ],
  );
}

ReadingSession _session({String question = ''}) {
  return ReadingSession(
    id: 'v2_session',
    deckId: 'rider-waite',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: question, topic: 'love'),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 8, 9),
    drawnCards: [
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(0).card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Geçmiş',
      ),
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(1).card,
        positionIndex: 1,
        isReversed: true,
        positionLabel: 'Şimdi',
      ),
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(2).card,
        positionIndex: 2,
        isReversed: false,
        positionLabel: 'Olası yön',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start copy and gem cost stay explicit', () {
    expect(
      TarotPolishCopy.startInstruction,
      'Bugün evren sana ne fısıldıyor?',
    );
    expect(TarotEconomy.readingCost, 20);
    expect(TarotPolishCopy.gemCost(20), '20 mücevher');
    expect(TarotPolishCopy.selectCards(3), '3 kart seç');
    expect(TarotPolishCopy.disclaimer, 'Bu, sembolik bir yorumdur.');
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false),
      contains(TarotPolishCopy.sourceLocal),
    );
    expect(
      TarotPolishCopy.askOracleHint,
      'İstersen bunu OR ile biraz daha açabiliriz.',
    );
  });

  test('intention can be skipped or kept', () {
    expect(const TarotIntention(text: '').isEmpty, isTrue);
    expect(
      const TarotIntention(text: 'İş konusunda önümde ne var?').isEmpty,
      isFalse,
    );
  });

  test('reading answers the question and still works without one', () {
    final withQuestion = ReflectiveReadingCopy.general(
      _context(question: 'Aşk hayatımda neye dikkat etmeliyim?'),
    );
    final withoutQuestion = ReflectiveReadingCopy.general(_context());
    expect(withQuestion, contains('Aşk hayatımda neye dikkat etmeliyim?'));
    expect(withQuestion, isNot(contains('Aşk hayatımda neye dikkat etmeliyim??')));
    expect(withoutQuestion, isNot(contains('Niyetin')));
    expect(withoutQuestion, isNotEmpty);
  });

  test('each card has meaning, spread message, note, and orientation', () {
    final upright = ReflectiveCardCopy.block(_context().cards.first);
    final reversed = ReflectiveCardCopy.block(_context().cards[1]);
    expect(upright, contains('Düz'));
    expect(upright, contains('Geçmiş'));
    expect(upright, contains('Yeni bir başlangıç'));
    expect(reversed, contains('Ters'));
    expect(reversed, contains('Dağınık niyet'));
    expect(upright.toLowerCase(), isNot(contains('iş ve yönde')));
  });

  test('generated reading keeps three cards and a summary', () async {
    final content = await TarotInterpretationService().generateContent(
      _session(question: 'Bu dönemde neyi bırakmalıyım?'),
    );
    expect(content.userQuestion, 'Bu dönemde neyi bırakmalıyım?');
    expect(content.generalMeaning, contains('bırakmalıyım'));
    expect(content.drawnCards, hasLength(3));
    expect(content.drawnCards[1].isReversed, isTrue);
    expect(content.cardReadings, contains('Ters'));
    expect(content.dailyAdvice, isNotEmpty);
    expect(content.promptQuestion, isNotEmpty);
    expect(content.promptQuestion.toLowerCase(), isNot(contains('mutlaka')));
    expect(content.love, isNotEmpty);
    expect(content.career, isEmpty);
  });

  test('OR context receives cards, orientations, spread, intention, summary', () {
    final session = _session(question: 'İş konusunda önümde ne var?');
    final content = AiReadingContent(
      cardName: 'Üç Kart Açılımı',
      tagline: 'Aşk',
      generalMeaning: 'Özet: işte küçük ve net bir adım yeterli.',
      love: '',
      career: '',
      money: '',
      spiritualGuidance: '',
      luckyEnergy: '',
      dailyAdvice: '',
      imageAsset: 'star.png',
      rarityColor: const Color(0xFF9B6DFF),
      fullInterpretation: 'Kartlar birlikte iş tablosunu sadeleştiriyor.',
      drawnCards: session.drawnCards,
    );
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: content,
    );
    expect(ctx.spreadLabel, 'Üç Kart');
    expect(ctx.userQuestion, 'İş konusunda önümde ne var?');
    expect(ctx.cardsSummary, contains('Ters'));
    expect(ctx.cardsSummary, contains('Düz'));
    expect(ctx.cardsSummary, contains('id:'));
    expect(ctx.cardNames, hasLength(3));
    expect(ctx.cardIds, hasLength(3));
    expect(ctx.interpretationSummary, contains('Özet'));
    expect(ctx.fullInterpretation, isNull);
  });

  test('history reopen keeps date, spread, intention, cards, summary', () {
    const markdown = '''
## Özet Mesaj
Sorduğun soru yanıtlandı: tempo tut.

## Kartlar
Kart: The Star (Düz)
Temel anlam: Umut.

Kart: The Moon (Ters)
Temel anlam: Belirsizlik.
''';
    final model = ReadingModel(
      id: 'v2_hist',
      cardId: 17,
      cardName: 'Üç Kart · The Star',
      cardImageAsset: 'star.png',
      spreadType: 'Üç Kart',
      aiSummary: markdown,
      createdAt: DateTime(2026, 8, 9, 10, 30),
      intention: 'İş konusunda önümde ne var?',
      readingType: 'İş konusunda önümde ne var?',
      cards: const [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'star.png',
          positionIndex: 0,
          positionLabel: 'Geçmiş',
        ),
        ReadingCardSnapshot(
          cardId: 18,
          cardName: 'The Moon',
          cardImageAsset: 'moon.png',
          positionIndex: 1,
          positionLabel: 'Şimdi',
          isReversed: true,
        ),
      ],
    );
    final entry = ReadingHistoryMapper.fromModel(model);
    final restored = ReadingModel.fromJson(model.toJson());
    final content = SavedReadingParser.toContent(entry: entry, model: restored);
    expect(restored.createdAt.day, 9);
    expect(restored.spreadType, 'Üç Kart');
    expect(restored.intention, 'İş konusunda önümde ne var?');
    expect(restored.cards[1].isReversed, isTrue);
    expect(content.generalMeaning, contains('tempo tut'));
    expect(content.userQuestion, 'İş konusunda önümde ne var?');
    expect(content.cardReadings, contains('Ters'));
    expect(entry.dateLabel, contains('2026'));
  });

  test('gem spend deducts once and blocks insufficient', () async {
    SharedPreferences.setMockInitialValues({});
    final wallet = GemWalletService(
      GemWalletStore(LocalStorage(await SharedPreferences.getInstance())),
    );
    await wallet.earn(amount: 50, reason: GemsCopy.reasonDailyReward);
    await wallet.spend(
      amount: TarotEconomy.readingCost,
      reason: GemsCopy.reasonTarot,
    );
    expect(wallet.balance, 30);
    expect(
      () => wallet.spend(amount: 40, reason: GemsCopy.reasonTarot),
      throwsA(
        isA<GemSpendException>().having(
          (e) => e.message,
          'message',
          GemsCopy.insufficient,
        ),
      ),
    );
    final first = wallet.spend(amount: 10, reason: GemsCopy.reasonTarot);
    expect(
      () => wallet.spend(amount: 10, reason: GemsCopy.reasonTarot),
      throwsA(isA<GemSpendException>()),
    );
    await first;
    expect(wallet.balance, 20);
  });

  testWidgets('start screen shows cost and blocks zero balance', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: TarotEpic031Page()),
      ),
    );
    await tester.pump();
    expect(find.text(TarotPolishCopy.startInstruction), findsOneWidget);
    expect(find.text('20 mücevher'), findsOneWidget);
    await tester.ensureVisible(find.text('RİTÜELE GİR'));
    await tester.tap(find.text('RİTÜELE GİR'));
    await tester.tap(find.text('RİTÜELE GİR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // The refusal now names the cost on a second line, so match the lead line.
    expect(find.textContaining(GemsCopy.insufficient), findsWidgets);
    expect(storage.getInt(GemWalletStore.balanceKey) ?? 0, 0);
  });

  testWidgets('start tap does not deduct gems before the reading begins',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      GemWalletStore.balanceKey: 50,
    });
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('next')),
          ),
          home: const TarotEpic031Page(),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('RİTÜELE GİR'));
    await tester.tap(find.text('RİTÜELE GİR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(storage.getInt(GemWalletStore.balanceKey), 50);
  });
}
