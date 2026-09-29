/// P3A — live Tarot chrome, deck label, and intention handoff honesty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_reading_context_text.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/reading/reading_question.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_flow.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  test('chamber title localizes and deck name is the catalogue label', () {
    expect(TarotL10n.chamberTitle, 'Tarot');
    expect(TarotL10n.deckName, 'Klasik Tarot');
    expect(TarotL10n.deckName, isNot('Rider-Waite'));

    OraclyL10n.bind('en');
    expect(TarotL10n.chamberTitle, 'Tarot');
    expect(TarotL10n.deckName, 'Classic Tarot');

    OraclyL10n.bind('ru');
    expect(TarotL10n.chamberTitle, 'Таро');
    expect(TarotL10n.deckName, 'Классическое Таро');
  });

  test('whitespace is not a question and topic ids stay localized', () {
    expect(ReadingQuestion.sanitize('   \n'), isEmpty);
    expect(ReadingQuestion.real('   '), isNull);

    expect(OracleReadingContextText.topicLabel('future'), 'Gelecek');
    expect(OracleReadingContextText.topicLabel('inner'), 'İç Dünyam');
    expect(
      OracleReadingContextText.topicLabel('custom'),
      'Kendi Sorumu Sor',
    );
    expect(
      OracleReadingContextText.tarotSourceLabel(topic: 'future'),
      'Tarot · Gelecek',
    );

    OraclyL10n.bind('ru');
    expect(OracleReadingContextText.tarotSourceLabel(), 'Таро');
    expect(
      OracleReadingContextText.tarotSourceLabel(topic: 'inner'),
      'Таро · Мой внутренний мир',
    );
  });

  test('table and reading OR context use the canonical deck name', () {
    final focus = CardRevealSpread.forIndex(0);
    final session = ReadingSession(
      id: 'p3a',
      deckId: 'classic',
      spread: TarotSpreadType.single,
      intention: const TarotIntention(text: 'Sessiz bir soru'),
      shuffleSeed: 1,
      startedAt: DateTime(2026, 9, 29),
      drawnCards: [
        TarotDrawnCard(
          card: focus.card,
          positionIndex: 0,
          isReversed: false,
        ),
      ],
    );
    final table = TarotTableFlow.buildOrContext(session: session, focus: focus);
    expect(table.deckName, 'Klasik Tarot');
    expect(table.sessionId, 'p3a');
    expect(table.userQuestion, 'Sessiz bir soru');
    expect(table.cardIds, [focus.card.id]);

    final full = OracleReadingContext.fromSession(
      session: session,
      content: AiReadingContent(
        cardName: focus.displayName,
        tagline: 't',
        generalMeaning: 'Kısa özet',
        love: '',
        career: '',
        money: '',
        spiritualGuidance: '',
        luckyEnergy: '',
        dailyAdvice: '',
        imageAsset: focus.imageAsset,
        rarityColor: const Color(0xFF9B6DFF),
      ),
    );
    expect(full.deckName, 'Klasik Tarot');
    expect(full.interpretationSummary, 'Kısa özet');
  });

  test('live spread picker offers only single, three, and five', () {
    expect(TarotTableSpreadOverlay.options, [
      TarotSpreadType.single,
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
    ]);
  });
}
