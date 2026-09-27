/// Dream Phase 2.2 — the one Turkish lexical matcher. Synthetic only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/text/turkish_lexical_matcher.dart';

bool told(String text, String token) =>
    TurkishLexicalMatcher.mentions(text, token);

void main() {
  test('word-start look-alikes are not the token', () {
    const collisions = {
      'Bir sunum yaptım.': 'su',
      'Dün çok yemek yedim.': 'yedi',
      'Evren çok büyüktü.': 'ev',
      'Evet dedim, evre değişti.': 'ev',
      'İşaret yanıp sönüyordu.': 'iş',
      'Ayrıca ayrı bir ayrıntı vardı.': 'ay',
      'Ateş yükseldi.': 'at',
      'İçimde bir kuşku vardı.': 'kuş',
      'Duvar soğuktu.': 'dua',
      'Huzursuz uyandım.': 'huzur',
      'Anneanneme gittim.': 'anne',
      'Eşik ve eşek gördüm.': 'eş',
      'Işın parladı.': 'iş',
      'Kapıcı bekliyordu.': 'kapı',
      'Masanın altında durdum.': 'altın',
      'Kedi yemek yedi.': 'yedi',
      'Balık yedi ve uyudu.': 'yedi',
    };
    collisions.forEach((text, token) {
      expect(told(text, token), isFalse, reason: '$token in "$text"');
    });
  });

  test('supported Turkish inflections are the token', () {
    const forms = {
      'ev': ['evde', 'eve', 'evden', 'evin', 'evi', 'evler', 'evlerde',
          'Evdeydim', 'evimizde'],
      'su': ['suda', 'suya', 'suyu', 'suyun', 'sudan', 'suyla', 'sular'],
      'ay': ['ayda', 'aya', 'ayın', 'Ayı', 'aydan', 'aylar', "Ay'ı"],
      'at': ['ata', 'atı', 'atta', 'attan', 'atlar'],
      'iş': ['işte', 'işe', 'işin', 'işler'],
      'kapı': ['kapıda', 'kapıya', 'kapıyı', 'kapının', 'kapılar'],
      'deniz': ['denizde', 'denize', 'denizin'],
      'kedi': ['kediyi', 'kedinin', 'kediler', 'kedimle'],
      'yedi': ['yedide', 'yediye', 'yediyi'],
      'köpek': ['köpeği', 'köpeğe', 'köpekler'],
      'şehir': ['şehre', 'şehri', 'şehirde'],
      'altın': ['altın', 'altınlar'],
    };
    forms.forEach((token, words) {
      for (final w in words) {
        expect(told('Rüyamda $w gördüm.', token), isTrue, reason: '$token/$w');
      }
    });
  });

  test('a bare numeral before a noun is the numeral', () {
    expect(told('Yedi kapı gördüm.', 'yedi'), isTrue);
    expect(told('Yediyi gördüm.', 'yedi'), isTrue);
  });

  test('numerals never take verb person endings', () {
    for (final w in ['yedim', 'yedin', 'yedik', 'yediler']) {
      expect(told('Dün $w.', 'yedi'), isFalse, reason: w);
    }
  });

  test('inflects compares single words', () {
    expect(TurkishLexicalMatcher.inflects('yilanin', 'yilan'), isTrue);
    expect(TurkishLexicalMatcher.inflects('yedim', 'yedi'), isFalse);
    expect(TurkishLexicalMatcher.inflects('sunum', 'su'), isFalse);
  });
}
