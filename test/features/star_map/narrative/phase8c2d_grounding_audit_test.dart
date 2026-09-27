/// Phase 8C.2d — full grounding lexical audit: Midheaven name, house word,
/// shared aspect/house helpers, and a multi-KB performance guard.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_lexical_token.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_aspect_grounding.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_body_grounding.dart';

import 'phase8c2d_support.dart';

void _body(String prose) => YildiznameQualityBodyGrounding.validate(
      phase8c2dRequest(),
      prose.toLowerCase(),
    );

void _houses(String prose) => YildiznameQualityAspectGrounding.validateHouses(
      phase8c2dRequest(),
      prose.toLowerCase(),
    );

RegExp _re(String source) => YildiznameLexicalToken.compile(source);

void main() {
  group('Midheaven needs its whole name, not bare "gökyüzü"', () {
    test('"Gökyüzünde Aslan …" (in the sky) is not a Midheaven claim', () {
      expect(
        () => _body('Gökyüzünde Aslan burcunda parlayan bir Güneş var.'),
        returnsNormally,
      );
      expect(() => _body('Gökyüzü açık, Koç burcu gibi.'), returnsNormally);
    });

    test('genuine Midheaven claims stay detectable', () {
      expect(() => _body('Gökyüzü ortası Kova burcunda.'), returnsNormally);
      expect(() => _body('Gökyüzü ortasında Kova duruyor.'), returnsNormally);
      expect(
        () => _body('Gökyüzü ortasında Aslan duruyor.'),
        groundingError('midheaven expected aquarius got leo'),
      );
      expect(
        () => _body('MC Aslan ile görünür.'),
        groundingError('midheaven expected aquarius got leo'),
      );
    });
  });

  group('house word is a real word', () {
    test('evre / evren / evet / household are not house claims', () {
      for (final prose in const [
        "Ay'ın 4 evresi sakin bir döngü anlatır.",
        'Güneş 3 evrede büyüyen bir fikir gibi.',
        'Ay 12 evren kadar geniş bir his.',
        'Mars 2 evet ve bir hayır arasında.',
        'The Moon feels like 5 household chores.',
      ]) {
        expect(() => _houses(prose), returnsNormally, reason: prose);
      }
    });

    test('genuine house claims stay detectable (right and wrong)', () {
      expect(() => _houses('Ay 7. evde sakin.'), returnsNormally);
      expect(() => _houses("Ay'ın 7. evindeki huzuru."), returnsNormally);
      expect(() => _houses('Güneş 10. evdeki görünürlük.'), returnsNormally);
      expect(() => _houses('Ay 4. evde duruyor.'), groundingError('house:moon:4'));
      expect(
        () => _houses('Venus in the 7 house claims partnership.'),
        groundingError('house:venus:7'),
      );
      expect(
        () => _houses('Mars 3. evlerinde koşar.'),
        groundingError('house:mars:3'),
      );
    });
  });

  group('shared helpers', () {
    test('aspect(): inflection yes, unrelated longer words no', () {
      final kare = _re(YildiznameLexicalToken.aspect('kare'));
      for (final w in ['kare', 'karesi', 'karesinde', 'kareye']) {
        expect(kare.hasMatch(w), isTrue, reason: w);
      }
      for (final w in ['kareli', 'karekök', 'mikare']) {
        expect(kare.hasMatch(w), isFalse, reason: w);
      }
      final trine = _re(YildiznameLexicalToken.aspect('trine'));
      expect(trine.hasMatch('trines'), isTrue);
      expect(trine.hasMatch('doctrine'), isFalse);
      final trin = _re(YildiznameLexicalToken.aspect('трин'));
      expect(trin.hasMatch('трине'), isTrue);
      expect(trin.hasMatch('тринадцать'), isFalse);
      final kv = _re(YildiznameLexicalToken.aspect('квадрат'));
      expect(kv.hasMatch('квадрате'), isTrue);
      expect(kv.hasMatch('квадратный'), isTrue);
      final sx = _re(YildiznameLexicalToken.aspect('секстил'));
      expect(sx.hasMatch('секстиль'), isTrue);
      expect(sx.hasMatch('секстиле'), isTrue);
      final ks = _re(YildiznameLexicalToken.aspect('karşıt'));
      expect(ks.hasMatch('karşıtlığında'), isTrue);
    });

    test('house(): ev / house / доме forms only', () {
      final house = _re(YildiznameLexicalToken.house());
      for (final w in ['ev', 'evde', 'evindeki', 'evlerinde', 'house', 'houses', 'доме']) {
        expect(house.hasMatch(w), isTrue, reason: w);
      }
      for (final w in ['evre', 'evren', 'evet', 'evlilik', 'household', 'домен']) {
        expect(house.hasMatch(w), isFalse, reason: w);
      }
    });
  });

  group('performance guard', () {
    test('body + house + aspect grounding stay fast on a multi-KB reading', () {
      final prose = List.generate(
        60,
        (_) =>
            'Bu detay—Mars kare gibi; bir olay—Mars kare; Sunset—Moon trine; '
            'Gökyüzünde Aslan; Ay\'ın 4 evresi; ayrıca güneşli bir sunum. ',
      ).join().toLowerCase();
      expect(prose.length, greaterThan(6000));
      final request = phase8c2dRequest();
      final sw = Stopwatch()..start();
      for (var i = 0; i < 5; i++) {
        YildiznameQualityBodyGrounding.validate(request, prose);
        YildiznameQualityAspectGrounding.validateHouses(request, prose);
        YildiznameQualityAspectGrounding.validateAspects(request, prose);
      }
      sw.stop();
      // ignore: avoid_print
      print('8C.2d grounding: 5 passes × ${prose.length} chars = '
          '${sw.elapsedMilliseconds} ms');
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });
  });
}
