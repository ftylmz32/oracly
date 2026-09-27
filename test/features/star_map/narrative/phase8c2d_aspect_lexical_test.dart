/// Phase 8C.2d — aspect-pair claims are read with the shared lexical rules.
///
/// Regression: the old raw `_pairAspect` began matching inside `detAY—Mars
/// kare`, reading ordinary prose as a Moon–Mars square. All prose here is
/// synthetic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_pair_aspect_matcher.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_aspect_grounding.dart';

import 'phase8c2d_support.dart';

void _aspects(String prose, {List<List<String>> known = const []}) =>
    YildiznameQualityAspectGrounding.validateAspects(
      phase8c2dRequest(
        aspects: [for (final k in known) aspectFact(k[0], k[1], k[2])],
      ),
      prose.toLowerCase(),
    );

void main() {
  group('collision prose creates NO aspect claim', () {
    const cases = [
      // reported
      'Bu detay—Mars kare gibi anlatıldı.',
      'Bir olay—Mars kare şeklinde anlatıldı.',
      'Kolay—Venüs üçgen gibi bir ifade.',
      'Sunum—Mars square başlıklı bir metin.',
      'Sunset—Moon trine adlı bir başlık.',
      // audit: other body collisions
      'Ayrıca—Mars kare gibi bir not düşüldü.',
      'Ayrıntı—Venüs üçgen başlığı altında.',
      'Sunucu—Moon trine diye bir etiket.',
      'Sunday—Moon trine is just a title.',
      'Güneşli—Mars kare bir öğleden sonra.',
      // audit: aspect-word collisions (the body pair itself is genuine)
      'Venus—Mars: a doctrine of balance.',
      'Ay—Mars kareli bir desen gibi.',
      'Güneş—Ay karekök gibi soyut bir kavram.',
      'Mars—Venüs üçgensel bir çizimde.',
      'Солнце — Луна: тринадцать лет спустя.',
    ];
    for (final prose in cases) {
      test(prose, () {
        expect(
          YildiznamePairAspectMatcher.claims(prose.toLowerCase()),
          isEmpty,
        );
        expect(() => _aspects(prose), returnsNormally);
      });
    }
  });

  group('genuine aspect claims are read with canonical names', () {
    const cases = <String, (String, String, String)>{
      'Ay—Mars kare': ('moon', 'mars', 'square'),
      'Ay – Mars kare': ('moon', 'mars', 'square'),
      'Ay—Mars karesi belirgin.': ('moon', 'mars', 'square'),
      'Güneş—Ay karşıt': ('sun', 'moon', 'opposition'),
      'Güneş—Ay karşıtlığı gerilim taşır.': ('sun', 'moon', 'opposition'),
      'Venüs—Mars kavuşumunda bir sıcaklık var.': (
        'venus',
        'mars',
        'conjunction',
      ),
      'Sun-Moon trine': ('sun', 'moon', 'trine'),
      'Venus — Mars square': ('venus', 'mars', 'square'),
      'Sun–Moon trines feel easy.': ('sun', 'moon', 'trine'),
      'Солнце — Луна в квадрате.': ('sun', 'moon', 'square'),
      'Венера — Марс: трин.': ('venus', 'mars', 'trine'),
      'Луна — Марс в оппозиции.': ('moon', 'mars', 'opposition'),
      'Марс — Венера секстиль.': ('mars', 'venus', 'sextile'),
      'Солнце — Луна соединение.': ('sun', 'moon', 'conjunction'),
    };
    cases.forEach((prose, expected) {
      final (a, b, type) = expected;
      test(prose, () {
        final claims =
            YildiznamePairAspectMatcher.claims(prose.toLowerCase()).toList();
        expect(claims, [(bodyA: a, bodyB: b, type: type)]);
        expect(() => _aspects(prose, known: [[a, b, type]]), returnsNormally);
        expect(() => _aspects(prose, known: [[b, a, type]]), returnsNormally);
        expect(() => _aspects(prose), groundingError('aspect:$a|$b|$type'));
      });
    });
  });

  group('wrong / unknown aspect rejection is preserved', () {
    test('right pair, wrong aspect type', () {
      expect(
        () => _aspects('Ay—Mars kare', known: [['moon', 'mars', 'trine']]),
        groundingError('aspect:moon|mars|square'),
      );
    });

    test('pair absent from evidence', () {
      expect(
        () => _aspects(
          'Venüs—Satürn kavuşum',
          known: [['moon', 'mars', 'square']],
        ),
        groundingError('aspect:venus|saturn|conjunction'),
      );
    });

    test('a genuine claim is never masked by a nearby collision word', () {
      expect(
        () => _aspects('Bu detay önemli. Ay—Mars kare gerilim taşır.'),
        groundingError('aspect:moon|mars|square'),
      );
      expect(
        () => _aspects('A doctrine aside, Sun-Moon trine is real.'),
        groundingError('aspect:sun|moon|trine'),
      );
    });

    test('Narrative corpus false conjunction still fails', () {
      expect(
        () => _aspects(
          'A Sun–Moon conjunction invents unity; evidence only has opposition.',
          known: [['sun', 'moon', 'opposition']],
        ),
        groundingError('aspect:sun|moon|conjunction'),
      );
    });
  });
}
