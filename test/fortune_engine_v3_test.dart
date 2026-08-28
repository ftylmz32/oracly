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
  CoffeeReading _cup({
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

  test('multi-symbol reading is a story, not four encyclopedia cards', () {
    OraclyL10n.bind('tr');
    final reading = _cup(
      id: 'story',
      observation: 'Fincanda kuş ve yol yan yana.',
      symbols: const [
        CoffeeSymbol(name: 'kuş', meaning: '', interpretation: ''),
        CoffeeSymbol(name: 'yol', meaning: '', interpretation: ''),
        CoffeeSymbol(name: 'kalp', meaning: '', interpretation: ''),
      ],
    );
    expect(reading.overall.toLowerCase(), contains('kuş'));
    expect(reading.overall.toLowerCase(), contains('yol'));
    expect(reading.overall.toLowerCase(), contains('haber'));
    expect(reading.overall, isNot(contains('Kuş = özellik')));
    expect(FortuneVoice.claimsCertainty(reading.overall), isFalse);
  });

  test('openings rotate by reading id without losing the symbols', () {
    OraclyL10n.bind('tr');
    const symbols = [
      CoffeeSymbol(name: 'yol', meaning: '', interpretation: ''),
    ];
    // Two ids can legitimately land on the same opening, so read the rotation
    // across a handful of cups instead of a single pair.
    final readings = [
      for (final id in ['alpha', 'omega', 'beta', 'delta', 'sigma', 'theta'])
        _cup(id: id, symbols: symbols, observation: 'Bir yol izi.').overall,
    ];
    expect(readings.toSet().length, greaterThan(1), reason: readings.join('|'));
    for (final reading in readings) {
      expect(reading.toLowerCase(), contains('yol'));
    }
  });

  test('personal change theme attaches only with path or key symbols', () {
    OraclyL10n.bind('tr');
    final withPath = _cup(
      id: 'p',
      symbols: const [CoffeeSymbol(name: 'yol', meaning: '', interpretation: '')],
      observation: 'Açık bir yol.',
      themes: const ['değişim'],
    );
    final noPath = _cup(
      id: 'n',
      observation: 'Fincanda duruluk.',
      themes: const ['değişim'],
    );
    expect(withPath.overall.toLowerCase(), contains('değişim'));
    expect(noPath.overall.toLowerCase(), isNot(contains('değişim')));
    expect(noPath.overall.toLowerCase(), isNot(contains('kalp')));
  });

  test('English and Russian stay natural and language-pure', () {
    const symbols = [
      CoffeeSymbol(name: 'bird', meaning: '', interpretation: ''),
      CoffeeSymbol(name: 'road', meaning: '', interpretation: ''),
    ];
    OraclyL10n.bind('en');
    final en = _cup(
      id: 'en',
      symbols: symbols,
      observation: 'A bird beside an open road.',
    );
    // Openings rotate by seed, so assert the shared shape: both marks named,
    // read as one pair, and no Turkish left in the English voice.
    expect(en.overall.toLowerCase(), contains('bird'));
    expect(en.overall.toLowerCase(), contains('road'));
    expect(
      RegExp('together|beside').hasMatch(en.overall.toLowerCase()),
      isTrue,
      reason: en.overall,
    );
    expect(en.overall, isNot(contains('ön plana')));
    expect(en.overall, isNot(matches(RegExp('[şğıİ]'))), reason: en.overall);
    expect(en.love, isEmpty);
    expect(en.career, isEmpty);
    OraclyL10n.bind('ru');
    final ru = _cup(
      id: 'ru',
      symbols: symbols,
      observation: 'Птица рядом с дорогой.',
    );
    expect(ru.overall, contains('рядом'));
    expect(ru.overall, isNot(contains('gündeme')));
    OraclyL10n.bind('tr');
  });

  test('palm never invents a missing line or a medical claim', () {
    OraclyL10n.bind('tr');
    final composed = PalmFortuneComposer.compose(
      PalmReading(
        id: 'hand',
        createdAt: DateTime(2026, 8, 16),
        hand: PalmHand.left,
        overall: 'Avuç geniş.',
        heartLine: 'Kalp çizgisi belirgin.',
        headLine: '',
      ),
    );
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
