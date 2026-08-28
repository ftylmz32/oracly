/// Tarot result as a revealed story — not a wall of sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_story_face.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/reading/reading_card_beat.dart';
import 'package:oracly_new/features/tarot/reading/reading_guidance.dart';
import 'package:oracly_new/features/tarot/reading/reading_question.dart';

ReadingCardContext _card() {
  return const ReadingCardContext(
    cardId: 1,
    cardName: 'The Magician',
    positionIndex: 1,
    positionLabel: 'Şimdi',
    positionKey: 'present',
    isReversed: true,
    uprightMeaning: 'Yaratıcı güç.',
    reversedMeaning: 'Dağınık niyet burada duruyor.',
    keywords: ['odak'],
  );
}

ReadingContext _ctx() {
  return ReadingContext(
    sessionId: 'story',
    spreadType: TarotSpreadType.threeCard,
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    language: 'tr',
    readingDate: DateTime(2026, 8, 18),
    userQuestion: 'İşimi bırakmalı mıyım?',
    cards: [_card()],
  );
}

AiReadingContent _content() {
  final drawn = [
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
  ];
  return AiReadingContent(
    cardName: 'Üç Kart Açılımı',
    tagline: 'Aşk',
    generalMeaning: 'Tema cümlesi.',
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: 'Kartlar birbirine değerek tek bir hikâye yazıyor.',
    dailyAdvice: 'Bugün tek net bakış yeterli.',
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: drawn,
    spreadLabel: 'Üç Kart',
    closingMessage: 'Bu açılımın sana bıraktığı yön, sade bir duruş.',
    userQuestion: 'İşimi bırakmalı mıyım?',
    readingTheme: 'career',
  );
}

int _sentenceCount(String text) {
  return RegExp(r'[^.!?…]+[.!?…]?')
      .allMatches(text.trim())
      .map((m) => m.group(0)?.trim() ?? '')
      .where((s) => s.isNotEmpty)
      .length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('copy names the story, the direction, and a real OR follow-up', () {
    expect(TarotPolishCopy.storyTitle, "ORACLY'nin Yorumu");
    expect(TarotPolishCopy.themeTitle, 'Ana Tema');
    expect(TarotPolishCopy.revealComplete, 'Açılım tamamlandı.');
    expect(TarotPolishCopy.relationsTitle, 'Kartların ilişkisi');
    expect(TarotPolishCopy.directionTitle, 'SANA BIRAKTIĞI YÖN');
    expect(TarotPolishCopy.orOpen, "OR'a Sor");
    expect(
      TarotPolishCopy.askOracleHint,
      'İstersen bunu OR ile biraz daha açabiliriz.',
    );
  });

  test('reveal faces stay visual — art, name, orientation, no interpretation wall', () {
    final faces = ReadingStoryFaceSpec.of(_content());
    expect(faces, hasLength(2));
    expect(faces.first.name, isNotEmpty);
    expect(faces.first.imageAsset, isNotEmpty);
    expect(faces.first.orientation, TarotPolishCopy.upright);
    expect(faces[1].orientation, TarotPolishCopy.reversed);
    expect(faces.first.position, 'Geçmiş');
    for (final face in faces) {
      expect(face.name, isNot(contains('Kartlar birbirine')));
      expect(face.orientation, isNot(contains('İşimi bırakmalı')));
    }
  });

  test('card insight is one line; expanded detail stays two to five sentences', () {
    final card = _card();
    final insight = ReadingCardBeat.insight(card);
    final detail = ReadingCardBeat.detail(
      card,
      question: 'İşimi bırakmalı mıyım?',
    );
    expect(insight, 'Dağınık niyet burada duruyor.');
    expect(insight, isNot(contains('Tek başına bir tanım değil')));
    expect(_sentenceCount(detail), inInclusiveRange(2, 5));
    expect(detail, contains('Dağınık niyet'));
  });

  test('direction is symbolic guidance, not a guaranteed future', () {
    final close = ReadingGuidance.closing(_ctx());
    expect(close, contains('Bu açılımın sana bıraktığı yön'));
    expect(close.toLowerCase(), isNot(contains('kesin olacak')));
    expect(close.toLowerCase(), isNot(contains('mutlaka')));
    expect(close, contains('acele bir cevap değil'));
  });

  test('OR follow-up carries the real spread, cards, and asked question', () {
    final content = _content();
    final session = ReadingSession(
      id: 'story_session',
      deckId: 'rider-waite',
      spread: TarotSpreadType.threeCard,
      intention: const TarotIntention(
        text: 'İşimi bırakmalı mıyım?',
        topic: 'career',
      ),
      shuffleSeed: 3,
      startedAt: DateTime(2026, 8, 18),
      drawnCards: content.drawnCards,
    );
    final ctx = OracleReadingContext.fromSession(
      session: session,
      content: content,
    );
    expect(ctx.userQuestion, 'İşimi bırakmalı mıyım?');
    expect(ctx.spreadLabel, 'Üç Kart');
    expect(ctx.cardNames, isNotEmpty);
    expect(ctx.cardIds, isNotEmpty);
    expect(ctx.cardsSummary, contains('id:'));
    expect(
      ctx.cardsSummary,
      contains(content.drawnCards.first.localizedName),
    );
    expect(ctx.interpretationSummary, contains('Tema'));
    expect(ctx.fullInterpretation, isNull);
  });

  test('share keeps the spread public and never leaks the asked question', () {
    final content = _content();
    final share = DiscoveryShareBuilder.tarot(
      theme: content.spreadLabel ?? content.readingTheme,
      cardName: content.cardName,
    );
    expect(share.caption, isNot(contains('İşimi bırakmalı mıyım?')));
    expect(share.highlight, isNot(contains('İşimi bırakmalı')));
    expect(ReadingQuestion.real(content.userQuestion), isNotNull);
  });
}
