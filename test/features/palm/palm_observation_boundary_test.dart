/// PalmObservation lexical rules match on Unicode token boundaries, never
/// raw substrings, and never leave a sentence whose antecedent was removed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/palm/data/palm_observation.dart';

void main() {
  group('absent marker "yok" is a whole word', () {
    test('standalone and punctuated "yok" match', () {
      expect(PalmObservation.hasTerm('yok', 'yok'), isTrue);
      expect(PalmObservation.hasTerm('yok.', 'yok'), isTrue);
      expect(PalmObservation.hasTerm('Belirgin bir kırık YOK.', 'yok'), isTrue);
      expect(PalmObservation.missing('Yön çizgisi yok.'), isTrue);
    });

    test('"yokluğundan" never matches "yok"', () {
      expect(PalmObservation.hasTerm('yokluğundan', 'yok'), isFalse);
      expect(PalmObservation.hasTerm('ayok yokç', 'yok'), isFalse);
      expect(
        PalmObservation.missing(
          'Sığ çizgi, duyguların yokluğundan çok ölçülü ifade edilmesine '
          'karşılık gelir.',
        ),
        isFalse,
      );
    });
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
