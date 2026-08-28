/// Tarot entry experience — question, spreads, no 78-card grid.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_position.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_choice.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('entry copy does not promise certainty', () {
    expect(TarotPolishCopy.startInstruction, contains('evren'));
    expect(TarotPolishCopy.startInstruction.toLowerCase(), isNot(contains('kesin')));
    expect(
      TarotPolishCopy.entryQuestionHint,
      'Aklındaki soruyu yaz... (isteğe bağlı)',
    );
    expect(TarotPolishCopy.entryQuestionHint.toLowerCase(), contains('iste'));
    expect(TarotPolishCopy.entryQuestionExamples, contains('İş değiştirmeli miyim?'));
    expect(TarotPolishCopy.startSpreadCta, 'RİTÜELE GİR');
  });

  test('offered spreads are 1, 3, 5, 7 — no fake occult math', () {
    final offered = TarotEntrySpreadChoice.offered();
    expect(offered.map((c) => c.type), [
      TarotSpreadType.single,
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
      TarotSpreadType.sevenCard,
    ]);
    expect(offered.map((c) => c.type.cardCount), [1, 3, 5, 7]);
    expect(TarotPolishCopy.spreadSingleBlurb, 'Bugün bilmem gereken ne?');
    expect(TarotPolishCopy.spreadThreeBlurb, 'Geçmiş · Şimdi · Gelecek');
    expect(TarotPolishCopy.spreadFiveBlurb, 'Durum · Zorluk · Güç · Yön');
    expect(
      TarotPolishCopy.spreadSevenBlurb,
      'Soru · Enerji · Engel · Gizli etken · Yardım · Kaçınılacak · Yön',
    );
  });

  test('seven-card layout is observational', () {
    final labels = SpreadService.positionsFor(TarotSpreadType.sevenCard)
        .map((p) => p.labelTr)
        .toList();
    expect(labels, [
      'Soru',
      'Şimdiki enerji',
      'Engel',
      'Gizli etken',
      'Yardımcı olan',
      'Kaçınılacak',
      'Yön',
    ]);
    expect(TarotSpreadType.fromTitle('Yedi Kart'), TarotSpreadType.sevenCard);
    expect(TarotSpreadType.fromTitle('seven card'), TarotSpreadType.sevenCard);
  });

  test('empty question remains a valid general reading', () {
    expect(const TarotIntention(text: '').isEmpty, isTrue);
    expect(const TarotIntention(text: '  ').isEmpty, isTrue);
  });

  test('reveal complete copy is calm', () {
    expect(TarotPolishCopy.revealComplete, 'Açılım tamamlandı.');
  });
}
