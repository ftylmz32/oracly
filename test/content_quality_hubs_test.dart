/// Content quality: 10 coffee + 10 astrology + 10 yıldızname, UI stripped.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/astrology/services/astrology_daily_reading_service.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/services/coffee_fortune_composer.dart';
import 'package:oracly_new/features/content/astrology/data/astrology_content_catalogue.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reading_presentation.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

const _banned = [
  'öne çıkmak doğru',
  'sabırsızlık yüzeye',
  'uzun hatta',
  'elimde yalnızca',
  'gökyüzü kataloğu',
  'tam harita değil',
  'doğum tarihi yoksa',
  'yalnızca bu burç',
  'sistem tespit',
  'yapay zeka',
  'güneşin için',
  'kesin gelecek değil',
  'özellikle ilginç',
  'hikâye tek oluyor',
      'ritminde, bugün seçilir',
      'keşif biriktirmemiz',
      'model detected',
      'this is not a complete chart',
      'iletişim ön plana',
      '...',
];

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('ten coffee readings speak to the cup, not the engine', () {
    final texts = _coffee();
    expect(texts, hasLength(10));
    _review(texts, requireToken: true);
  });

  test('ten astrology readings never expose implementation', () {
    final texts = _astrology();
    expect(texts, hasLength(10));
    _review(texts, requireToken: true);
    for (final text in texts) {
      expect(text.toLowerCase(), isNot(contains('elimde')));
      expect(text.toLowerCase(), contains('gökyüz'));
      expect(text, contains(RegExp(r'Koç|Boğa|İkizler|Yengeç|Aslan|Başak')));
    }
  });

  test('ten yıldızname chapters are one story, not four cookie cards', () {
    final packs = _star();
    expect(packs, hasLength(10));
    for (final pack in packs) {
      _review(pack, requireToken: false, minOpenings: 2);
      expect(pack.toSet().length, greaterThanOrEqualTo(3), reason: pack.join(' | '));
      final joined = pack.join(' ').toLowerCase();
      expect(joined, isNot(contains('uzun hatta')));
      expect(joined, isNot(contains('doğum tarihi yoksa')));
      expect(joined, isNot(contains('keşif biriktirmemiz')));
      expect(joined, contains('içeride'));
      expect(joined, contains('son dönem'));
      expect(joined, contains('eşik'));
    }
  });

  test('low-trust coffee mark stays uncertain', () {
    final reading = CoffeeFortuneComposer.compose(
      CoffeeReading(
        id: 'faint',
        createdAt: DateTime(2026, 8, 18),
        overall: '',
        love: 'Aşkta mutlaka düğün var.',
        career: 'Terfi kesin.',
        money: '',
        nearFuture: '',
        takeaway: '',
        visualObservation: 'Ağızda belirsiz bir iz.',
        symbols: const [
          CoffeeSymbol(
            name: 'kuş',
            meaning: '',
            interpretation: '',
            trust: CoffeeMarkTrust.low,
          ),
        ],
      ),
    );
    expect(reading.overall.toLowerCase(), contains('net değil'));
    expect(reading.overall.toLowerCase(), contains('kuş'));
    expect(reading.love, isEmpty);
    expect(reading.career, isEmpty);
  });
}

void _review(
  List<String> texts, {
  required bool requireToken,
  int minOpenings = 5,
}) {
  final openings = <String>{};
  for (var i = 0; i < texts.length; i++) {
    final text = texts[i];
    expect(text.trim(), isNotEmpty, reason: 'empty $i');
    final lower = text.toLowerCase();
    for (final phrase in _banned) {
      expect(lower, isNot(contains(phrase)), reason: 'reading $i: $phrase\n$text');
    }
    expect(HumanReader.looksGeneric(text), isFalse, reason: text);
    expect(text.contains('...'), isFalse, reason: text);
    openings.add(text.split('.').first.trim());
    if (requireToken) {
      expect(
        _someone(lower),
        isTrue,
        reason: 'anyone-test failed: $text',
      );
    }
  }
  expect(openings.length, greaterThanOrEqualTo(minOpenings));
}

bool _someone(String lower) {
  // Every symbol the fixtures place in a cup, plus the softened stems Turkish
  // produces when the copy inflects them ("kalp" → "kalbe", "mektup" → "mektuba").
  const tokens = [
    'kuş',
    'yol',
    'kalp',
    'kalb',
    'yüzük',
    'yüzüğ',
    'anahtar',
    'dağ',
    'göz',
    'ağaç',
    'ağac',
    'mektup',
    'mektub',
    'koç',
    'boğa',
    'ikizler',
    'yengeç',
    'aslan',
    'başak',
    'senin',
    'sende',
    'fincan',
  ];
  return tokens.any(lower.contains);
}

List<String> _coffee() {
  const cups = [
    ['kuş', 'yol'],
    ['kalp', 'yüzük'],
    ['yol', 'anahtar'],
    ['dağ'],
    ['kuş'],
    ['göz', 'yol'],
    ['ağaç', 'yol'],
    ['mektup'],
    ['kalp'],
    ['anahtar'],
  ];
  return [
    for (var i = 0; i < cups.length; i++)
      CoffeeFortuneComposer.compose(
        CoffeeReading(
          id: 'cup-$i',
          createdAt: DateTime(2026, 8, 18),
          overall: '',
          love: i == 1 ? 'Yakınlıkta net bir cümle iyi gelir.' : '',
          career: i == 2 ? 'Tek işi bitirmek kazandırır.' : '',
          money: '',
          nearFuture: '',
          takeaway: '',
          visualObservation: 'Ağızda ${cups[i].join(' ve ')} duruyor.',
          symbols: [
            for (final name in cups[i])
              CoffeeSymbol(name: name, meaning: '', interpretation: ''),
          ],
        ),
        themes: i == 2 ? const ['değişim'] : const [],
      ).overall,
  ];
}

List<String> _astrology() {
  final signs = AstrologyContentCatalogue.signs.take(6).toList();
  return [
    for (var i = 0; i < 10; i++)
      AstrologyDailyReadingService.build(
        signs[i % signs.length],
        now: DateTime(2026, 8, 10 + i),
      ).overall,
  ];
}

List<List<String>> _star() {
  return [
    for (var i = 0; i < 10; i++)
      () {
        final reading = StarMapReadingService.build(
          now: DateTime(2026, 8, 10 + i),
          sunSign: i.isEven ? ZodiacSignId.aries : ZodiacSignId.leo,
        );
        return [
          StarMapReadingPresentation.todayBody(reading),
          StarMapReadingPresentation.innerBody(reading),
          StarMapReadingPresentation.journeyBody(reading),
          StarMapReadingPresentation.thresholdBody(reading),
        ];
      }(),
  ];
}
