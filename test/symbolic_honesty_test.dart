/// Trust and symbolic honesty — mystical, never certain.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/copy/transparency_copy.dart';
import 'package:oracly_new/core/honesty/symbolic_honesty.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/personality/or_core.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/prompt_engine/templates/sections/shared_sections.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/reading/reading_story.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('layers stay distinct: observed, interpreted, possible, unknown', () {
    expect(OrCore.epistemic.toLowerCase(), contains('gözlenen'));
    expect(OrCore.epistemic.toLowerCase(), contains('yorumlanan'));
    expect(OrCore.epistemic.toLowerCase(), contains('olası'));
    expect(OrCore.epistemic.toLowerCase(), contains('bilinmeyen'));
    expect(SymbolicHonesty.prompt, contains('gözlenen'));
    expect(SymbolicHonesty.prompt, contains('geleneksel yorumda'));
    expect(SharedTemplateSections.basePersona, contains(SymbolicHonesty.prompt));
  });

  test('coffee observes a shape, then traditional reading — not a sure headline', () {
    expect(OraclyL10n.t('cup.shape.bird'), 'kuşa benzeyen bir şekil');
    expect(OraclyL10n.t('cup.read.look.0'), contains('{seen}'));
    expect(OraclyL10n.t('fortune.cup.single'), contains('Geleneksel okumada'));
    expect(OraclyL10n.t('fortune.cup.single'), contains('net bir sonuç'));
    final reading = CoffeeFortuneComposer.compose(
      CoffeeReading(
        id: 'bird-cup',
        createdAt: DateTime(2026, 8, 19),
        overall: 'Kesin haber alacaksın.',
        love: '',
        career: '',
        money: '',
        nearFuture: '',
        takeaway: '',
        visualObservation: 'Ağızda kuş gibi bir iz.',
        symbols: const [
          CoffeeSymbol(
            name: 'kuş',
            meaning: 'haber',
            interpretation: 'Kesin haber alacaksın.',
            trust: CoffeeMarkTrust.high,
          ),
        ],
      ),
    );
    expect(reading.overall.toLowerCase(), contains('kuş'));
    expect(reading.overall, contains('Geleneksel okumada'));
    expect(FortuneVoice.claimsCertainty(reading.overall), isFalse);
    expect(reading.overall.toLowerCase(), isNot(contains('kesin haber alacaksın')));
  });

  test('tarot points toward a stance, never a guaranteed future', () {
    OraclyL10n.bind('en');
    expect(
      TarotL10n.fill('tarot.story.open.a', {
        'thread': 'work',
        'pos': 'Now',
        'name': 'The Magician',
        'hedge': 'can be read this way',
        'meaning': 'Focus.',
      }),
      contains('This spread points toward'),
    );
    OraclyL10n.bind('tr');
    final story = ReadingStory.opening(
      ReadingContext(
        sessionId: 's',
        spreadType: TarotSpreadType.single,
        spreadLabel: 'Tek Kart',
        deckId: 'classic',
        language: 'tr',
        readingDate: DateTime(2026, 8, 19),
        cards: const [
          ReadingCardContext(
            cardId: 1,
            cardName: 'The Magician',
            positionIndex: 0,
            positionLabel: 'Şimdi',
            positionKey: 'present',
            isReversed: false,
            uprightMeaning: 'Odak.',
            reversedMeaning: 'Dağınık niyet.',
            keywords: ['odak'],
          ),
        ],
      ),
    );
    expect(story, contains('işaret ediyor'));
    expect(FortuneVoice.claimsCertainty(story), isFalse);
    expect(story.toLowerCase(), isNot(contains('kesinlikle')));
  });

  test('honesty is a quiet symbolic line, not a legal wall', () {
    for (final line in [
      TransparencyCopy.interpretationBrief,
      CoffeeCopy.disclaimer,
      PalmCopy.disclaimer,
      DreamCopy.disclaimer,
      TarotPolishCopy.disclaimer,
      StarMapPolishCopy.symbolicDisclaimer,
    ]) {
      expect(SymbolicHonesty.isQuietHonesty(line), isTrue);
      expect(line.toLowerCase(), isNot(contains('yasal')));
      expect(line.toLowerCase(), isNot(contains('sorumluluk')));
      expect(line.split(' ').length, lessThanOrEqualTo(8));
    }
  });
}
