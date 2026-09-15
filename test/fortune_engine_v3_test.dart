/// Fortune-reader engine V3: connected symbols, no fake history, natural voice.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';

void main() {
  CoffeeReading? _cup({
    required String id,
    List<CoffeeSymbol> symbols = const [],
    String observation = '',
    List<String> themes = const [],
  }) {
    return CoffeeFortuneComposer.compose(
      CoffeeReading(
        id: id,
        createdAt: DateTime(2026, 8, 16),
        overall: 'iletişim ön plana çıkabilir',
        love: 'duygusal bir hareketlilik yaşanabilir',
        career: 'yeni fırsatlar olabilir',
        money: '',
        nearFuture: 'gündeme gelebilir',
        takeaway: '',
        visualObservation: observation,
        symbols: symbols,
      ),
      themes: themes,
    );
  }

  test(
    'BATCH 3A.2: no client story/opening-rotation/theme-attachment/'
    'locale-weaving engine remains — a raw-dump backend overall fails '
    'composition regardless of symbols, themes, or language',
    () {
      OraclyL10n.bind('tr');
      expect(
        _cup(
          id: 'story',
          observation: 'Fincanda kuş ve yol yan yana.',
          symbols: const [
            CoffeeSymbol(name: 'kuş', meaning: '', interpretation: ''),
            CoffeeSymbol(name: 'yol', meaning: '', interpretation: ''),
            CoffeeSymbol(name: 'kalp', meaning: '', interpretation: ''),
          ],
        ),
        isNull,
      );
      expect(
        _cup(
          id: 'p',
          symbols: const [CoffeeSymbol(name: 'yol', meaning: '', interpretation: '')],
          observation: 'Açık bir yol.',
          themes: const ['değişim'],
        ),
        isNull,
      );
      OraclyL10n.bind('en');
      expect(
        _cup(
          id: 'en',
          symbols: const [
            CoffeeSymbol(name: 'bird', meaning: '', interpretation: ''),
            CoffeeSymbol(name: 'road', meaning: '', interpretation: ''),
          ],
          observation: 'A bird beside an open road.',
        ),
        isNull,
      );
      OraclyL10n.bind('ru');
      expect(
        _cup(
          id: 'ru',
          symbols: const [
            CoffeeSymbol(name: 'bird', meaning: '', interpretation: ''),
            CoffeeSymbol(name: 'road', meaning: '', interpretation: ''),
          ],
          observation: 'Птица рядом с дорогой.',
        ),
        isNull,
      );
      OraclyL10n.bind('tr');
    },
  );

  test('palm never invents a missing line or a medical claim', () {
    OraclyL10n.bind('tr');
    final composed = PalmFortuneComposer.compose(
      PalmReading(
        id: 'hand',
        createdAt: DateTime(2026, 8, 16),
        hand: PalmHand.left,
        overall: 'Avuç geniş; sakin ama net bir yapı hissettiriyor.',
        heartLine: 'Kalp çizgisi belirgin.',
        headLine: '',
      ),
    )!;
    expect(composed.headLine, isEmpty);
    expect(composed.heartLine, isNotEmpty);
    expect(FortuneVoice.claimsMedical(composed.fullText), isFalse);
    expect(composed.lifeLine, isEmpty);
  });

  test('soulmate uses real inputs and no arrival certainty', () {
    OraclyL10n.bind('en');
    final text = SoulMateInterpretation.forRequest(
      SoulMateDrawRequest(
        name: 'Ayse',
        birthDate: DateTime(1994, 3, 12),
        intention: 'calm companionship',
      ),
    );
    expect(text, contains('Ayse'));
    expect(text.toLowerCase(), contains('calm'));
    expect(text.toLowerCase(), isNot(contains('will enter your life')));
    expect(FortuneVoice.claimsCertainty(text), isFalse);
    OraclyL10n.bind('tr');
  });
}
