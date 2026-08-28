/// Tarot → OR handoff — minimal context, no internal leak.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/contexts/oracle_context_mapper.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/oracle_prompt_builder.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';

ReadingSession _session({required String question}) {
  return ReadingSession(
    id: 'or_handoff_session',
    deckId: 'rider-waite',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: question, topic: 'career'),
    shuffleSeed: 99,
    startedAt: DateTime(2026, 8, 19),
    drawnCards: [
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(0).card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Geçmiş',
        positionKey: 'past',
      ),
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(1).card,
        positionIndex: 1,
        isReversed: true,
        positionLabel: 'Şimdi',
        positionKey: 'present',
      ),
    ],
  );
}

AiReadingContent _content(ReadingSession session) {
  return AiReadingContent(
    cardName: 'Üç Kart Açılımı',
    tagline: 'Kariyer',
    generalMeaning: 'Özet: işte küçük ve net bir adım yeterli.',
    love: 'Aşk bölümü — OR promptuna gitmemeli.',
    career: 'Kariyer bölümü — OR promptuna gitmemeli.',
    money: 'Para bölümü — OR promptuna gitmemeli.',
    spiritualGuidance: 'Günlük bölüm — OR promptuna gitmemeli.',
    luckyEnergy: 'Genel yorum — OR promptuna gitmemeli.',
    dailyAdvice: 'Bugün mesajı — OR promptuna gitmemeli.',
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    fullInterpretation: 'Ham markdown — OR promptuna gitmemeli.',
    cardReadings: 'Kart anlamları — OR promptuna gitmemeli.',
    drawnCards: session.drawnCards,
    userQuestion: session.intention.text,
    spreadLabel: session.spread.label,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('button copy opens OR from the reading footer', () {
    expect(TarotPolishCopy.orOpen, "OR'a Sor");
  });

  test('fromSession passes only minimum tarot context', () {
    const question = 'Bu kartlara göre neyi görmezden geliyorum?';
    final session = _session(question: question);
    final content = _content(session);
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: content,
    );

    expect(ctx.userQuestion, question);
    expect(ctx.spreadLabel, 'Üç Kart');
    expect(ctx.cardIds, hasLength(2));
    expect(ctx.cardIds.first, session.drawnCards.first.card.id);
    expect(ctx.cardsSummary, contains('id:${session.drawnCards.first.card.id}'));
    expect(ctx.cardsSummary, contains('Geçmiş'));
    expect(ctx.cardsSummary, contains('Düz'));
    expect(ctx.cardsSummary, contains('Ters'));
    expect(ctx.interpretationSummary, contains('Özet'));
    expect(ctx.fullInterpretation, isNull);
    expect(ctx.interpretationSummary.length, lessThan(400));
  });

  test('AI prompt carries spread, cards, summary, question — not full history', () {
    final session = _session(question: 'İşimi bırakmalı mıyım?');
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: _content(session),
    );
    final ai = OracleContextMapper.fromOracle(ctx) as TarotAiContext;
    final block = OraclePromptBuilder.messages(
      context: ai,
      userMessage: 'Bu kartlara göre neyi görmezden geliyorum?',
    ).firstWhere((m) => m['role'] == 'user')['content']! as String;

    expect(block, contains('İşimi bırakmalı mıyım?'));
    expect(block, contains('Üç Kart'));
    expect(block, contains('id:'));
    expect(block, contains('Özet'));
    expect(block, isNot(contains('or_handoff_session')));
    expect(block, isNot(contains('shuffleSeed')));
    expect(block, isNot(contains('Aşk bölümü')));
    expect(block, isNot(contains('Kart anlamları')));
    expect(block, isNot(contains('Ham markdown')));
  });

  test('metadata round-trip keeps card ids without inventing context', () {
    final session = _session(question: 'Net adım ne?');
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: _content(session),
    );
    final restored = OracleReadingContext.fromMetadata(ctx.toMetadata());
    expect(restored.cardIds, ctx.cardIds);
    expect(restored.userQuestion, ctx.userQuestion);
    expect(restored.cardsSummary, ctx.cardsSummary);
    expect(restored.fullInterpretation, isNull);
  });
}
