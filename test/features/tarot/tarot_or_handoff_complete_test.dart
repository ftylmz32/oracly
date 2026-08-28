/// Tarot -> OR handoff: minimum context, visible transfer, no history dump.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/production/contexts/oracle_context_mapper.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/oracle_prompt_builder.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_handoff_banner.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_discovery_handoff_quality.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';

ReadingSession _session({required String question, String? topic}) {
  return ReadingSession(
    id: 'or_handoff_session',
    deckId: 'rider-waite',
    spread: TarotSpreadType.threeCard,
    intention: TarotIntention(text: question, topic: topic),
    shuffleSeed: 99,
    startedAt: DateTime(2026, 8, 19),
    drawnCards: [
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(0).card,
        positionIndex: 0,
        isReversed: false,
        positionLabel: 'Gecmis',
        positionKey: 'past',
      ),
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(1).card,
        positionIndex: 1,
        isReversed: true,
        positionLabel: 'Simdi',
        positionKey: 'present',
      ),
    ],
  );
}

AiReadingContent _content(ReadingSession session) {
  return AiReadingContent(
    cardName: 'Spread',
    tagline: 'love',
    generalMeaning: 'Özet: kalpte net bir adim yeterli.',
    love: 'LOVE_SECTION_LEAK',
    career: 'CAREER_SECTION_LEAK',
    money: 'MONEY_SECTION_LEAK',
    spiritualGuidance: 'SPIRIT_SECTION_LEAK',
    luckyEnergy: 'LUCKY_SECTION_LEAK',
    dailyAdvice: 'DAILY_SECTION_LEAK',
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    fullInterpretation: 'FULL_MARKDOWN_LEAK',
    cardReadings: 'CARD_READINGS_LEAK',
    drawnCards: session.drawnCards,
    userQuestion: session.intention.text,
    spreadLabel: session.spread.label,
    readingTheme: session.intention.topic,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('fromSession carries feature, topic, question, cards, summary only', () {
    const question = 'Bu bağ bana mı ait?';
    final session = _session(question: question, topic: 'love');
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: _content(session),
    );

    expect(ctx.kind, OracleReadingKind.tarot);
    expect(ctx.sourceLabel, 'Tarot · Aşk');
    expect(ctx.userQuestion, question);
    expect(ctx.spreadLabel, 'Üç Kart');
    expect(ctx.cardIds, hasLength(2));
    expect(ctx.interpretationSummary, contains('Özet'));
    expect(ctx.fullInterpretation, isNull);
    expect(ctx.interpretationSummary.length, lessThan(400));
  });

  test('compact handoff strips ids and stays under cap', () {
    final session = _session(question: 'Ne yapmaliyim?', topic: 'love');
    final compact = OrChatHandoff.compact(
      OracleReadingContext.fromSession(
        session: session,
        content: _content(session),
      ),
    );
    expect(compact.startsWith('Tarot'), isTrue);
    expect(compact, contains('Aşk'));
    expect(compact, contains('Soru: Ne yapmaliyim?'));
    expect(compact, isNot(contains('id:')));
    expect(compact, isNot(contains('or_handoff_session')));
    expect(compact, isNot(contains('LOVE_SECTION_LEAK')));
    expect(compact.length, lessThanOrEqualTo(OrDiscoveryHandoffQuality.maxTotal));
  });

  test('prompt and styleHint keep INTERPRETATION without full history', () {
    final session = _session(question: 'Bu iliski nereye gidiyor?', topic: 'love');
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: _content(session),
    );
    final ai = OracleContextMapper.fromOracle(ctx) as TarotAiContext;
    final block = OraclePromptBuilder.messages(
      context: ai,
      userMessage: 'Biraz daha ac.',
    ).firstWhere((m) => m['role'] == 'user')['content']! as String;

    expect(block, contains('Bu iliski nereye gidiyor?'));
    expect(block, isNot(contains('FULL_MARKDOWN_LEAK')));
    expect(block, isNot(contains('LOVE_SECTION_LEAK')));

    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Biraz daha ac.',
      recentMessages: const [],
      featureHandoff: OrChatHandoff.compact(ctx),
    );
    expect(hint, contains('INTERPRETATION'));
    expect(hint, contains('Tarot'));
    expect(hint.length, lessThanOrEqualTo(480));
  });

  testWidgets('handoff banner names the transfer for the user', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionHandoffBanner(
            compact: 'Tarot · Aşk\nSoru: Bu bağ bana mı ait?\nThe Moon',
          ),
        ),
      ),
    );
    expect(find.text(CompanionCopy.handoffBannerTarot), findsOneWidget);
    expect(find.textContaining('Tarot'), findsWidgets);
    expect(CompanionHandoffBanner.of('hello'), isNull);
    expect(CompanionHandoffBanner.of('Tarot\nSoru: x'), isNotNull);
  });

  test('arrival line tells the user context is already held', () {
    expect(
      OrChatHandoff.arrivalLine(
        const OracleReadingContext(
          sessionId: 's1',
          spreadLabel: 'Tek Kart',
          deckId: 'classic',
          deckName: 'Classic',
          readingTitle: 'Kart',
          cardsSummary: 'Kart',
          interpretationSummary: 'Özet',
          kind: OracleReadingKind.tarot,
          sourceLabel: 'Tarot · Aşk',
        ),
      ),
      contains('kartlar burada'),
    );
  });
}
