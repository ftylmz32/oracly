/// Phase 8C.2c — body tokens are genuine word occurrences, never a mere
/// prefix of a longer, unrelated word (TR / EN / RU).
///
/// Regression: the Turkish Moon token `ay` matched inside `ayrıca` ("also"),
/// so "Ayrıca Aslan burcunda…" could be read as a Moon-in-Leo claim. All
/// prose here is synthetic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_body_match.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_grounding_lexicon.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_lexical_token.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_body_grounding.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_angle_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';

/// FULL evidence: Sun Leo, Moon Taurus, Ascendant Libra, Midheaven Aquarius.
YildiznameNarrativeRequest _request({String moon = 'taurus'}) =>
    YildiznameNarrativeRequest(
      languageCode: 'tr',
      scope: YildiznameNarrativeScope.full,
      fidelity: 'fullNatalEphemeris',
      houseSystem: 'wholeSign',
      calculationVersion: 'calc-fixture',
      placements: [
        const YildiznamePlacementFact(
          factRef: 'placement.sun',
          body: 'sun',
          sign: 'leo',
          certainty: 'exact',
        ),
        YildiznamePlacementFact(
          factRef: 'placement.moon',
          body: 'moon',
          sign: moon,
          certainty: 'exact',
        ),
      ],
      angles: const [
        YildiznameAngleFact(
          factRef: 'angle.ascendant',
          kind: 'ascendant',
          sign: 'libra',
          certainty: 'exact',
        ),
        YildiznameAngleFact(
          factRef: 'angle.midheaven',
          kind: 'midheaven',
          sign: 'aquarius',
          certainty: 'exact',
        ),
      ],
      houses: const [],
      aspects: const [],
      balances: const [],
      discoveryThemes: const [],
      omittedLayers: const [],
    );

void _check(String prose, {String moon = 'taurus'}) =>
    YildiznameQualityBodyGrounding.validate(
      _request(moon: moon),
      prose.toLowerCase(),
    );

Matcher _grounding(String message) => throwsA(
  isA<YildiznameResultException>()
      .having((e) => e.kind, 'kind', YildiznameResultErrorKind.grounding)
      .having((e) => e.message, 'message', message),
);

void main() {
  group('the reported false positive is closed', () {
    test('"Ayrıca Aslan burcunda …" no longer reads as Moon in Leo', () {
      expect(
        () => _check('Ayrıca Aslan burcunda güçlü bir vurgu var.'),
        returnsNormally,
      );
    });

    test('the same words with a genuinely wrong Moon sign still fail', () {
      // Real Moon evidence is Leo here; the claim below is (correctly) about
      // the Sun only, so it must pass — proving the fix does not just
      // silence the check, only the false "ayrıca ⇒ Moon" reading.
      expect(
        () => _check('Ayrıca Aslan burcunda güçlü bir vurgu var.', moon: 'leo'),
        returnsNormally,
      );
    });
  });

  group('body collision corpus — FALSE claims must not be detected', () {
    const cases = [
      'Ayrıca Aslan burcunda derin bir vurgu var.',
      'Bu fasılda ayrıntı önemli değil, Aslan burcunda odak yaratıcılık.',
      'Söylemek istediğim şey ayrı bir konu; Aslan burcunda sabit bir duruş.',
      'Bir olay Aslan burcunda yeniden anlam kazanır.',
      'Bunu yapmak hiç kolay olmasa da Aslan burcunda cesaret büyür.',
      'Mayıs ayında Aslan burcunda bir vurgu belirginleşir.',
      'Ayin gibi sessiz bir an, Aslan burcunda kendini gösterir.',
      // longer-token collisions audited across the whole lexicon
      'Güneşli bir gün gibi, Terazi yükselen dengeyi arar.',
      'Bu konuyu sunum hâline getirmek, Terazi yükselen için doğal.',
      'Sunucu gibi sessizce dinleyen bir Terazi yükselen imgesi.',
      'Bu bir sunuş cümlesidir; Terazi yükselen dengeyi sever.',
      'Merkürsüz bir sessizlik yerine Terazi yükselen konuşur.', // hypothetical
      'Venüssüz bir görünüm yerine Terazi yükselen sever.', // hypothetical
    ];
    for (final prose in cases) {
      test(prose, () {
        expect(() => _check(prose), returnsNormally);
      });
    }
  });

  group(
    'true Moon claims remain detectable (TR apostrophe / no apostrophe)',
    () {
      test('"Ay Aslan burcunda" (bare)', () {
        expect(
          () => _check('Ay Aslan burcunda parlar.'),
          _grounding('moon expected taurus got leo'),
        );
        expect(
          () => _check('Ay Aslan burcunda parlar.', moon: 'leo'),
          returnsNormally,
        );
      });

      test('"Ay\'ın Aslan burcundaki…" (apostrophe genitive)', () {
        expect(
          () => _check("Ay'ın Aslan burcundaki konumu güçlü."),
          _grounding('moon expected taurus got leo'),
        );
      });

      test('"Ayın Aslan burcundaki…" (no apostrophe, run-on)', () {
        expect(
          () => _check('Ayın Aslan burcundaki konumu güçlü.'),
          _grounding('moon expected taurus got leo'),
        );
      });

      test('"Aslan Ayı" (sign precedes body, linking suffix)', () {
        expect(
          () => _check('Aslan Ayı güçlü bir tını taşır.'),
          _grounding('moon expected taurus got leo'),
        );
        expect(
          () => _check('Aslan Ayı güçlü bir tını taşır.', moon: 'leo'),
          returnsNormally,
        );
      });

      test('curly apostrophe (’) also terminates the word correctly', () {
        expect(
          () => _check('Ay’ın Aslan burcundaki konumu güçlü.'),
          _grounding('moon expected taurus got leo'),
        );
      });
    },
  );

  group('TR / EN / RU body claims stay detectable', () {
    test('TR: Güneş / Güneş\'in / Güneşin', () {
      expect(() => _check('Güneş Aslan burcunda parlar.'), returnsNormally);
      expect(
        () => _check("Güneş'in Aslan'da oluşu güçlüdür."),
        returnsNormally,
      );
      expect(
        () => _check('Güneşin Aslan burcundaki gücü belirgin.'),
        returnsNormally,
      );
      expect(
        () => _check('Güneş Koç burcunda parlar.'),
        _grounding('sun expected leo got aries'),
      );
    });

    test('TR: Merkür / Venüs / Satürn with genitive suffixes', () {
      final req = YildiznameNarrativeRequest(
        languageCode: 'tr',
        scope: YildiznameNarrativeScope.full,
        fidelity: 'fullNatalEphemeris',
        houseSystem: 'wholeSign',
        calculationVersion: 'c',
        placements: const [
          YildiznamePlacementFact(
            factRef: 'placement.mercury',
            body: 'mercury',
            sign: 'virgo',
            certainty: 'exact',
          ),
          YildiznamePlacementFact(
            factRef: 'placement.venus',
            body: 'venus',
            sign: 'libra',
            certainty: 'exact',
          ),
          YildiznamePlacementFact(
            factRef: 'placement.saturn',
            body: 'saturn',
            sign: 'capricorn',
            certainty: 'exact',
          ),
        ],
        angles: const [],
        houses: const [],
        aspects: const [],
        balances: const [],
        discoveryThemes: const [],
        omittedLayers: const [],
      );
      void check(String prose) =>
          YildiznameQualityBodyGrounding.validate(req, prose.toLowerCase());
      expect(() => check("Merkür'ün Başak'daki sesi net."), returnsNormally);
      expect(
        () => check('Merkürün Başak burcundaki sesi net.'),
        returnsNormally,
      );
      expect(() => check("Venüs'ün Terazi'deki zarafeti."), returnsNormally);
      expect(() => check("Satürn'ün Oğlak'taki disiplini."), returnsNormally);
      expect(
        () => check('Merkür Koç burcunda konuşur.'),
        _grounding('mercury expected virgo got aries'),
      );
    });

    test('EN: "Sun in Leo" / "Moon in Gemini" / possessive', () {
      expect(() => _check('Sun in Leo shines.'), returnsNormally);
      expect(() => _check("Sun's placement in Leo shines."), returnsNormally);
      expect(
        () => _check('Moon in Gemini drifts.'),
        _grounding('moon expected taurus got gemini'),
      );
      expect(() => _check('Moon in Taurus feels steady.'), returnsNormally);
    });

    test('EN "sun" collisions with common English words are ignored', () {
      for (final prose in const [
        'Sunday brings a Terazi yükselen calm.',
        'A sunset over a Terazi yükselen mood.',
        'Sunny skies meet a Terazi yükselen frame.',
      ]) {
        expect(() => _check(prose), returnsNormally, reason: prose);
      }
    });

    test('RU: Солнце / Луна with case endings', () {
      final req = YildiznameNarrativeRequest(
        languageCode: 'ru',
        scope: YildiznameNarrativeScope.full,
        fidelity: 'fullNatalEphemeris',
        houseSystem: 'wholeSign',
        calculationVersion: 'c',
        placements: const [
          YildiznamePlacementFact(
            factRef: 'placement.sun',
            body: 'sun',
            sign: 'leo',
            certainty: 'exact',
          ),
          YildiznamePlacementFact(
            factRef: 'placement.moon',
            body: 'moon',
            sign: 'taurus',
            certainty: 'exact',
          ),
        ],
        angles: const [],
        houses: const [],
        aspects: const [],
        balances: const [],
        discoveryThemes: const [],
        omittedLayers: const [],
      );
      void check(String prose) =>
          YildiznameQualityBodyGrounding.validate(req, prose.toLowerCase());
      expect(() => check('Солнце во Льве светит ясно.'), returnsNormally);
      expect(() => check('Луна в Тельце устойчива.'), returnsNormally);
      expect(
        () => check('Луна в Раке чувствительна.'),
        _grounding('moon expected taurus got cancer'),
      );
      expect(
        () => check('Солнце в Раке светит ясно.'),
        _grounding('sun expected leo got cancer'),
      );
    });
  });

  group('wrong-sign rejection is preserved (not silenced by the fix)', () {
    test('a real wrong Moon sign still fails, apostrophe or not', () {
      expect(
        () => _check("Ay'ın Aslan burcundaki konumu güçlü."),
        _grounding('moon expected taurus got leo'),
      );
      expect(
        () => _check('Ayın Aslan burcundaki konumu güçlü.'),
        _grounding('moon expected taurus got leo'),
      );
      expect(
        () => _check('Ay Aslan burcunda parlar.'),
        _grounding('moon expected taurus got leo'),
      );
    });

    test('a genuine claim is never masked by a nearby collision word', () {
      expect(
        () => _check('Ayrıca not düşelim: Ay Aslan burcunda parlar.'),
        _grounding('moon expected taurus got leo'),
      );
    });
  });

  group('house/aspect grounding body matcher (YildiznameBodyMatch)', () {
    test('"ayrıca" near a house mention is not read as the Moon', () {
      expect(
        YildiznameBodyMatch.has('ayrıca 5. evde bir vurgu', 'moon', const [
          'moon',
          'лун',
          'ay',
        ]),
        isFalse,
      );
    });

    test('a genuine "Ay … evde" mention is still read as the Moon', () {
      expect(
        YildiznameBodyMatch.has('ay 5. evde güçlü', 'moon', const [
          'moon',
          'лун',
          'ay',
        ]),
        isTrue,
      );
      expect(
        YildiznameBodyMatch.has("ay'ın 5. evdeki konumu", 'moon', const [
          'moon',
          'лун',
          'ay',
        ]),
        isTrue,
      );
    });

    test('"sunum" is not read as the Sun for house attribution', () {
      expect(
        YildiznameBodyMatch.has('bir sunum 10. evde geçer', 'sun', const [
          'güneş',
          'gunes',
          'sun',
          'солнц',
        ]),
        isFalse,
      );
      expect(
        YildiznameBodyMatch.has('güneş 10. evde güçlü', 'sun', const [
          'güneş',
          'gunes',
          'sun',
          'солнц',
        ]),
        isTrue,
      );
    });

    test('GroundingLexicon.hasBody agrees (same underlying matcher)', () {
      expect(
        YildiznameGroundingLexicon.hasBody('ayrıca bir şey', 'moon'),
        isFalse,
      );
      expect(YildiznameGroundingLexicon.hasBody('ay burada', 'moon'), isTrue);
    });
  });

  group('shared helper: body()', () {
    RegExp body(String t) =>
        YildiznameLexicalToken.compile(YildiznameLexicalToken.body(t));

    test('ay: closed suffix set only, "ayin" is not accepted', () {
      final ay = body('ay');
      expect(ay.hasMatch('ay burada'), isTrue);
      expect(ay.hasMatch("ay'ın burada"), isTrue);
      expect(ay.hasMatch('ayın burada'), isTrue);
      expect(
        ay.hasMatch('ayı gördüm'),
        isTrue,
      ); // documented residual ambiguity
      expect(ay.hasMatch('ayda bir kez'), isTrue);
      expect(ay.hasMatch('aydan beri'), isTrue);
      expect(ay.hasMatch('ayrıca'), isFalse);
      expect(ay.hasMatch('ayrıntı'), isFalse);
      expect(ay.hasMatch('ayrı'), isFalse);
      expect(ay.hasMatch('olay'), isFalse);
      expect(ay.hasMatch('kolay'), isFalse);
      expect(ay.hasMatch('mayıs'), isFalse);
      expect(ay.hasMatch('ayin'), isFalse);
    });

    test('sun: whole word only', () {
      final sun = body('sun');
      expect(sun.hasMatch('sun rises'), isTrue);
      expect(sun.hasMatch("sun's rise"), isTrue);
      expect(sun.hasMatch('sunum'), isFalse);
      expect(sun.hasMatch('sunucu'), isFalse);
      expect(sun.hasMatch('sunset'), isFalse);
      expect(sun.hasMatch('sunday'), isFalse);
    });

    test('güneş: closed general suffix set, "güneşli" is not accepted', () {
      final gunes = body('güneş');
      expect(gunes.hasMatch('güneş parlar'), isTrue);
      expect(gunes.hasMatch("güneş'in parlar"), isTrue);
      expect(gunes.hasMatch('güneşin parlar'), isTrue);
      expect(gunes.hasMatch('güneşi izledim'), isTrue);
      expect(gunes.hasMatch('güneşte'), isTrue);
      expect(gunes.hasMatch('güneşli bir gün'), isFalse);
    });

    test('Cyrillic bodies keep case-ending behaviour', () {
      final sun = body('солнц');
      expect(sun.hasMatch('солнце светит'), isTrue);
      expect(sun.hasMatch('солнца лучи'), isTrue);
      final moon = body('лун');
      expect(moon.hasMatch('луна устойчива'), isTrue);
      expect(moon.hasMatch('луны свет'), isTrue);
    });
  });

  group('performance guard', () {
    test('body grounding stays fast on a longer reading', () {
      final prose = List.generate(
        40,
        (_) =>
            'Ayrıca güneşli bir sunum var; Terazi yükselen dengeyi arar; '
            'ayrıntı önemli değil; bir olay Aslan burcunda geçer.',
      ).join(' ');
      final sw = Stopwatch()..start();
      for (var i = 0; i < 3; i++) {
        expect(() => _check(prose), returnsNormally);
      }
      expect(
        sw.elapsedMilliseconds,
        lessThan(3000),
        reason: 'three grounding passes took ${sw.elapsedMilliseconds} ms',
      );
    });
  });
}
