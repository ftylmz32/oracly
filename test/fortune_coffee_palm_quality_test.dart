/// Coffee/Palm fortune copy quality — grounded, not robotic, not invented.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/openai/coffee_prompt_style.dart';
import 'package:oracly_new/features/ai/production/openai/palm_prompt_style.dart';
import 'package:oracly_new/features/coffee/data/coffee_symbol_lexicon.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_narration.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test(
    'BATCH 3A.2: coffee never fabricates a symbol-woven story from '
    'symbols/themes alone — a short/missing backend overall fails '
    'composition instead',
    () {
      final composed = CoffeeFortuneComposer.compose(
        CoffeeReading(
          id: 'c1',
          createdAt: DateTime(2026, 8, 15),
          overall: 'iletişim ön plana çıkabilir',
          love: 'duygusal bir hareketlilik yaşanabilir',
          career: 'İş hayatında yeni fırsatlar olabilir.',
          money: 'yeni fırsatlar gündeme gelebilir',
          nearFuture: 'gündeme gelebilir',
          takeaway: '',
          visualObservation:
              'Fincanın ağız kısmındaki açık yol ve uçan bir kuş.',
          symbols: const [
            CoffeeSymbol(name: 'kuş', meaning: '', interpretation: ''),
            CoffeeSymbol(name: 'yol', meaning: '', interpretation: ''),
          ],
        ),
        themes: const ['değişim'],
      );
      expect(composed, isNull);
      expect(CoffeeSymbolLexicon.match('kuş')!.id, 'bird');
    },
  );

  test(
    'BATCH 3A.2: a short backend overall never gets padded into an '
    'invented story, with or without symbols',
    () {
      final composed = CoffeeFortuneComposer.compose(
        CoffeeReading(
          id: 'c2',
          createdAt: DateTime(2026, 8, 15),
          overall: 'Fincanda duruluk var.',
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: '',
          visualObservation: 'Fincanda duruluk var.',
        ),
      );
      expect(composed, isNull);
    },
  );

  test('palm copy is grounded and never medical', () {
    final composed = PalmFortuneComposer.compose(
      PalmReading(
        id: 'p1',
        createdAt: DateTime(2026, 8, 15),
        hand: PalmHand.right,
        overall:
            'El geniş ve belirgin çizgili; tempo hızlı değil, temkinli bir '
            'yapı hissettiriyor.',
        heartLine: 'Kalp çizgisinin belirgin yapısı.',
        headLine: 'Zihin çizgisi net ve uzun.',
        lifeLine: 'Yaşam çizgisi kavisli.',
        fateLine: 'Yön çizgisi zayıf.',
      ),
    )!;
    expect(composed.heartLine, contains('Kalp çizgisinin belirgin yapısı'));
    expect(composed.heartLine.toLowerCase(), isNot(contains('vazgeçmeyen')));
    expect(composed.lifeLine, contains('kavisli'));
    expect(composed.lifeLine.toLowerCase(), isNot(contains('hastalık')));
    expect(FortuneVoice.claimsMedical(composed.fullText), isFalse);
    expect(FortuneVoice.claimsCertainty(composed.fullText), isFalse);
    final spoken = PalmFortuneNarration.body(composed);
    expect(spoken, contains(composed.overall));
    expect(spoken, contains(composed.heartLine));
    expect(spoken, isNot(contains('\n\n\n')));
  });

  test('prompt asks for traditional grounded coffee prose', () {
    expect(CoffeePromptStyle.system, contains('3–5 cümle'));
    expect(CoffeePromptStyle.system, contains('Uydurma sembol'));
    expect(CoffeePromptStyle.system, contains('Her okumayı soru ile bitirme'));
    expect(CoffeePromptStyle.system, contains('cümle çeşitliliği'));
    expect(CoffeePromptStyle.userLead, contains('gorselTespit'));
    expect(CoffeePromptStyle.userLead, contains('Kuş+yol'));
    expect(CoffeePromptStyle.userLead, isNot(contains('sonda bir soru')));
    expect(CoffeePromptStyle.userLead, contains('zorunlu soru yok'));
    expect(PalmPromptStyle.system, contains('Her okumayı soru ile bitirme'));
    expect(PalmPromptStyle.userLead, contains('zorunlu soru yok'));
    expect(PalmPromptStyle.system, contains('hastalık'));
    expect(PalmPromptStyle.system, contains('ölüm'));
    expect(PalmPromptStyle.system, contains('Tek hikâye'));
    expect(PalmPromptStyle.userLead, contains('kalpCizgisi'));
  });
}
