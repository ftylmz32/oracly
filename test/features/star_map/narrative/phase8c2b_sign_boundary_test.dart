/// Phase 8C.2b — sign tokens are real WORDS, never substrings (TR / EN / RU).
///
/// Regression: the Turkish Sagittarius token `yay` matched inside `dünyaya`
/// ("to the world"), so a correct "Terazi yükselen, dünyaya …" failed with
/// `ascendant expected libra got sagittarius`. All prose here is synthetic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_lexical_token.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_body_grounding.dart';
import 'package:oracly_new/features/star_map/narrative/quality/yildizname_quality_grounding.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_angle_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_section.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_narrative_structured_result.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_section_kind.dart';
import 'package:oracly_new/features/star_map/narrative/versions.dart';

/// FULL evidence: Sun Leo, Moon Taurus, Ascendant [asc], Midheaven Aquarius.
YildiznameNarrativeRequest _request({String asc = 'libra'}) =>
    YildiznameNarrativeRequest(
      languageCode: 'tr',
      scope: YildiznameNarrativeScope.full,
      fidelity: 'fullNatalEphemeris',
      houseSystem: 'wholeSign',
      calculationVersion: 'calc-fixture',
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
      angles: [
        YildiznameAngleFact(
          factRef: 'angle.ascendant',
          kind: 'ascendant',
          sign: asc,
          certainty: 'exact',
        ),
        const YildiznameAngleFact(
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

/// Runs the body/sign grounding on already-lowercased prose (as production).
void _check(String prose, {String asc = 'libra'}) =>
    YildiznameQualityBodyGrounding.validate(
      _request(asc: asc),
      prose.toLowerCase(),
    );

Matcher _grounding(String message) => throwsA(
  isA<YildiznameResultException>()
      .having((e) => e.kind, 'kind', YildiznameResultErrorKind.grounding)
      .having((e) => e.message, 'message', message),
);

void main() {
  group('the reported false positive is closed', () {
    test('"Terazi yükselen, dünyaya …" no longer reads as Sagittarius', () {
      expect(
        () => _check('Terazi yükselen, dünyaya yaklaşımında uyum arar.'),
        returnsNormally,
      );
    });

    test('the same words with a wrong Ascendant still fail as LIBRA', () {
      // Sagittarius evidence: the (correct-for-Libra) claim is a wrong sign.
      expect(
        () => _check(
          'Terazi yükselen, dünyaya yaklaşımında uyum arar.',
          asc: 'sagittarius',
        ),
        _grounding('ascendant expected sagittarius got libra'),
      );
    });

    for (final prose in const [
      'Terazi yükselen, dünyaya bakışı dengelidir.',
      'Terazi yükselen; yayın ve yaygın etkiler.',
      'Terazi yükselen, kayayı bile yumuşatır.',
      'Terazi yükselen, dünyayı okur.',
      'Yükselen Terazi ve yayılan bir sıcaklık.',
    ]) {
      test('substring "yay" inside a longer word is ignored: $prose', () {
        expect(() => _check(prose), returnsNormally);
      });
    }
  });

  group('true Sagittarius is still Sagittarius', () {
    test('standalone "Yay yükselen" against Libra evidence FAILS', () {
      expect(
        () => _check('Yay yükselen, ufku geniş tutar.'),
        _grounding('ascendant expected libra got sagittarius'),
      );
    });

    test('"Yükselen Yay" against Libra evidence FAILS', () {
      expect(
        () => _check('Yükselen Yay, yeni yollar açar.'),
        _grounding('ascendant expected libra got sagittarius'),
      );
    });

    test('apostrophe forms are real word ends: Yay\'da / Yay’da', () {
      for (final apostrophe in const ["'", '’']) {
        expect(
          () => _check('Yükselen Yay${apostrophe}da doğar.'),
          _grounding('ascendant expected libra got sagittarius'),
          reason: 'apostrophe $apostrophe',
        );
      }
    });

    test('a correct Sagittarius Ascendant passes against Sagittarius', () {
      expect(
        () => _check('Yay yükselen, dünyaya açılır.', asc: 'sagittarius'),
        returnsNormally,
      );
      expect(
        () => _check('Yükselen Yay, yolu sever.', asc: 'sagittarius'),
        returnsNormally,
      );
    });
  });

  group('valid claims stay detectable in TR / EN / RU', () {
    test('TR: Terazi yükselen / Yükselen Terazi', () {
      expect(() => _check('Terazi yükselen ve sakin.'), returnsNormally);
      expect(() => _check('Yükselen Terazi ve sakin.'), returnsNormally);
      expect(
        () => _check('Terazi yükselen ve sakin.', asc: 'scorpio'),
        _grounding('ascendant expected scorpio got libra'),
      );
      expect(
        () => _check('Yükselen Terazi ve sakin.', asc: 'scorpio'),
        _grounding('ascendant expected scorpio got libra'),
      );
    });

    test('EN: "Libra rising" and "Ascendant in Libra"', () {
      expect(() => _check('Libra rising invites balance.'), returnsNormally);
      expect(
        () => _check('Ascendant in Libra invites balance.'),
        returnsNormally,
      );
      expect(
        () => _check('Libra rising invites balance.', asc: 'aries'),
        _grounding('ascendant expected aries got libra'),
      );
      expect(
        () => _check('Ascendant in Libra invites balance.', asc: 'aries'),
        _grounding('ascendant expected aries got libra'),
      );
    });

    test('RU: асцендент в <знак> with case endings', () {
      expect(
        () => _check('Асцендент в Скорпионе задаёт тон.', asc: 'scorpio'),
        returnsNormally,
      );
      expect(
        () => _check('Асцендент в Скорпионе задаёт тон.'),
        _grounding('ascendant expected libra got scorpio'),
      );
    });

    test('TR: dotted İ survives lowercasing (İkizler yükselen)', () {
      expect(
        () => _check('İkizler yükselen merakı büyütür.'),
        _grounding('ascendant expected libra got gemini'),
      );
      expect(
        () => _check('İkizler yükselen merakı büyütür.', asc: 'gemini'),
        returnsNormally,
      );
    });

    test('planet + sign claims still work (TR / EN)', () {
      expect(() => _check('Güneş Aslan\'da parlar.'), returnsNormally);
      expect(() => _check('Sun in Leo shines.'), returnsNormally);
      expect(
        () => _check('Güneş Koç\'ta parlar.'),
        _grounding('sun expected leo got aries'),
      );
      expect(
        () => _check('Güneş Koç burcunda parlar.'),
        _grounding('sun expected leo got aries'),
      );
      expect(
        () => _check('Sun in Aries shines.'),
        _grounding('sun expected leo got aries'),
      );
      expect(
        () => _check('Moon in Gemini drifts.'),
        _grounding('moon expected taurus got gemini'),
      );
    });

    test('the sign may also precede the body (Aslan Güneşi)', () {
      expect(
        () => _check('Koç Güneşi cesur olur.'),
        _grounding('sun expected leo got aries'),
      );
    });
  });

  group('short-token red team: no claim from inside another word', () {
    for (final prose in const [
      // koç (Aries) inside koçluk / koçak
      'Terazi yükselen ve koçluk gibi destek.',
      'Güneş Aslan\'da; koçak bir tavır.',
      // leo (Leo) inside Leonardo / galleon
      'Libra rising with a Leonardo-like curiosity.',
      'Libra rising, a galleon of ideas.',
      // rak / cancer / virgo style substrings in longer words
      'Libra rising and virgola-free prose.',
      // scorpio inside scorpions
      'Libra rising among scorpions and other myths.',
      // lev / рак style Cyrillic stems inside other words
      'Асцендент левый берег, ветер и ракушки.',
    ]) {
      test('no wrong-sign failure: $prose', () {
        expect(() => _check(prose), returnsNormally);
      });
    }

    test('the moon token "ay" must start a word (olay ≠ Ay)', () {
      // "olay Aslan burcunda" used to read as "Moon in Leo".
      expect(
        () => _check('Güneş Aslan\'da; bir olay Aslan burcunda anılır.'),
        returnsNormally,
      );
    });

    test('a genuine wrong-sign claim is never masked by a nearby word', () {
      expect(
        () => _check('Terazi yükselen, dünyaya bakar; Güneş Koç\'ta.'),
        _grounding('sun expected leo got aries'),
      );
    });
  });

  group('shared helper', () {
    RegExp sign(String t) =>
        YildiznameLexicalToken.compile(YildiznameLexicalToken.sign(t));

    test('Latin sign names are whole words', () {
      final yay = sign('yay');
      expect(yay.hasMatch('yay yükselen'), isTrue);
      expect(yay.hasMatch('yükselen yay.'), isTrue);
      expect(yay.hasMatch("yay'da"), isTrue);
      expect(yay.hasMatch('yay’da'), isTrue);
      expect(yay.hasMatch('dünyaya'), isFalse);
      expect(yay.hasMatch('yayın'), isFalse);
      expect(yay.hasMatch('yaygın'), isFalse);
      expect(yay.hasMatch('kayayı'), isFalse);
    });

    test(
      'boundaries understand Turkish and Cyrillic letters, not just ASCII',
      () {
        // ASCII-only \b would call "ç" a boundary and accept "koçluk" style
        // splits; \p{L} does not.
        expect(sign('koç').hasMatch('koçluk'), isFalse);
        expect(sign('koç').hasMatch('bir koç.'), isTrue);
        expect(sign('лев').hasMatch('левый'), isFalse);
        expect(sign('лев').hasMatch('знак лев.'), isTrue);
      },
    );

    test('Cyrillic stems take a case ending, Latin names do not', () {
      expect(sign('скорпион').hasMatch('в скорпионе'), isTrue);
      expect(sign('скорпион').hasMatch('со скорпионом'), isTrue);
      expect(sign('aslan').hasMatch('aslanda'), isFalse);
      expect(sign('aslan').hasMatch("aslan'da"), isTrue);
    });

    test('normalizeProse folds the dotted-İ combining mark', () {
      // Some runtimes lowercase "İkizler" to "i" + U+0307 + "kizler".
      const decomposed = 'i̇kizler';
      expect(sign('ikizler').hasMatch(decomposed), isFalse);
      expect(
        sign(
          'ikizler',
        ).hasMatch(YildiznameLexicalToken.normalizeProse(decomposed)),
        isTrue,
      );
    });
  });

  group('performance guard', () {
    test('grounding does not recompile patterns per call (UI-thread safe)', () {
      // A ~4 KB reading. Recompiling thousands of Unicode patterns on every
      // validation once cost ~10 s per call on a PC and froze a phone for ~50 s.
      final prose = List.generate(
        40,
        (_) =>
            'Terazi yükselen, dünyaya bakışında uyum arar. Güneş Aslan burcunda '
            'parlar; yayın ve yaygın etkiler koçluk gibi destek olur.',
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

  group('the full grounding stage (visible prose) agrees', () {
    YildiznameNarrativeStructuredResult result(String summary) =>
        YildiznameNarrativeStructuredResult(
          contractVersion: kYildiznameResultContractVersion,
          languageCode: 'tr',
          scope: YildiznameNarrativeScope.full,
          summary: YildiznameNarrativeBlock(
            text: summary,
            factRefs: const ['angle.ascendant'],
            themeRefs: const [],
          ),
          sections: [
            YildiznameNarrativeSection(
              kind: YildiznameSectionKind.coreIdentity,
              text: 'Sakin bir netlik aranıyor.',
              factRefs: const ['placement.sun'],
              themeRefs: const [],
            ),
          ],
          reflectionPrompt: null,
          closingMessage: 'Kendi ritmine dön.',
        );

    test('correct Libra prose with "dünyaya" passes the stage', () {
      expect(
        () => YildiznameQualityGrounding.validate(
          _request(),
          result('Terazi yükselen, dünyaya yaklaşımında uyum arar.'),
        ),
        returnsNormally,
      );
    });

    test('a real Sagittarius claim still fails the stage', () {
      expect(
        () => YildiznameQualityGrounding.validate(
          _request(),
          result('Yay yükselen, ufku geniş tutar.'),
        ),
        _grounding('ascendant expected libra got sagittarius'),
      );
    });
  });
}
