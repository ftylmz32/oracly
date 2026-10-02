/// PalmObservation lexical rules match on Unicode token boundaries, never
/// raw substrings, and never leave a sentence whose antecedent was removed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/palm/data/palm_observation.dart';

void main() {
  group('missing() means the line itself is unavailable', () {
    const absentLines = [
      'Yok.',
      'yok',
      'Çizgi yok.',
      'Kalp çizgisi yok.',
      'Yön çizgisi burada yok.',
      'Bu çizgi görünmüyor.',
      'Çizgi görülemiyor.',
      'Çizgi seçilemiyor.',
      'Line not visible.',
      'Too faint to identify the line.',
    ];
    for (final text in absentLines) {
      test('absent: "$text"', () {
        expect(PalmObservation.missing(text), isTrue);
      });
    }

    const presentLines = [
      'Yaşam çizgisi uzun bir yay çiziyor; kopukluk yok.',
      'Baş çizgisinde kesinti yok, avucu boydan boya geçiyor.',
      'Belirgin bir kırılma yok.',
      'Dallanma yok.',
      'Çizgide boşluk yok.',
      'Kalp çizgisinin yokluğundan söz edilemez.',
      'Sığ çizgi, duyguların yokluğundan çok ölçülü ifade edilmesine '
          'karşılık gelir.',
      'Kalp çizgisi net; yukarı doğru hiçbir dallanma yok.',
    ];
    for (final text in presentLines) {
      test('present (a property is denied, not the line): "$text"', () {
        expect(PalmObservation.missing(text), isFalse);
        // "dallanma" is separately a textbook term; that rule, not absence,
        // decides whether such a sentence is shown.
        if (!PalmObservation.hasTerm(text, 'dallanma')) {
          expect(PalmObservation.line(text), isNotEmpty);
        }
      });
    }
  });

  group('textbook term "ölüm" starts at a token boundary', () {
    test('standalone and punctuated "ölüm" match', () {
      expect(PalmObservation.hasTerm('ölüm', 'ölüm'), isTrue);
      expect(PalmObservation.hasTerm('ölüm.', 'ölüm'), isTrue);
      expect(PalmObservation.hasTerm('Bu bir ÖLÜM işareti.', 'ölüm'), isTrue);
    });

    test('"bölüm" and "bölümünde" never match "ölüm"', () {
      expect(PalmObservation.hasTerm('bölüm', 'ölüm'), isFalse);
      expect(PalmObservation.hasTerm('bölümünde', 'ölüm'), isFalse);
    });

    test('a sentence containing "bölümünde" survives grounding', () {
      const sentence = 'Uzun, hafifçe aşağı kıvrılan ve görünür bölümünde '
          'belirgin kopukluk taşımayan baş çizgisi; bir konuyu yüzeyde '
          'bırakmayan zihinsel eğilimi çağrıştırır.';
      expect(PalmObservation.ground(sentence), sentence);
    });

    test('a sentence naming death is still dropped', () {
      expect(PalmObservation.ground('Bu çizgi ölüm anlamına gelir.'), isEmpty);
    });
  });

  group('honest unavailable-line markers', () {
    test('"görülemiyor" and "seçilemiyor" mark a line unavailable', () {
      expect(PalmObservation.missing('Görülemiyor.'), isTrue);
      expect(PalmObservation.missing('GÖRÜLEMİYOR'), isTrue);
      expect(PalmObservation.missing('Kader çizgisi seçilemiyor.'), isTrue);
      expect(PalmObservation.line('Görülemiyor.'), isEmpty);
    });
  });

  group('dangling continuation after a removed sentence', () {
    test('"Bu ayrım" is dropped when its "dallanma" antecedent is removed', () {
      expect(
        PalmObservation.ground(
          'Kalp çizgisinin ucunda küçük bir dallanma seçiliyor. Bu ayrım, '
          'duygularını iki yönde tarttığını düşündürüyor ve seçerken acele '
          'etmediğini gösteriyor.',
        ),
        isEmpty,
      );
    });

    test('a demonstrative opener is kept when its antecedent survives', () {
      const text = 'Kalp çizgisi yumuşak bir yay çiziyor. '
          'Bu yapı, yakınlıkta sabrı anlatıyor.';
      expect(PalmObservation.ground(text), text);
    });

    test('an independent sentence after the dropped pair survives', () {
      expect(
        PalmObservation.ground(
          'Uçta bir dallanma var. Bu ayrım iki yönü anlatıyor. '
          'Kalp çizgisi yumuşak bir yay çiziyor.',
        ),
        'Kalp çizgisi yumuşak bir yay çiziyor.',
      );
    });
  });
}
