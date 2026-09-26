/// Phase 7C — truthful natal fact projection (red-team matrix A–X).
///
/// Facts come ONLY from the stored structured request, capped by the resolved
/// scope, honoring `omittedLayers`, failing closed on malformed evidence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_projector.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_snapshot.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_presentation.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';
import 'package:oracly_new/features/star_map/result/yildizname_scope_resolver.dart';

import '../../../support/yildizname_result_fixtures.dart';

const _full = YildiznameNarrativeScope.full;
const _reduced = YildiznameNarrativeScope.reduced;
const _legacy = YildiznameNarrativeScope.legacy;

Map<String, dynamic> _req(
  YildiznameNarrativeScope scope, {
  bool ascendant = true,
  bool midheaven = true,
  bool houses = true,
  bool aspects = true,
  bool rich = false,
}) => yildiznameFixtureRequest(
  scope: scope,
  ascendant: ascendant,
  midheaven: midheaven,
  houses: houses,
  aspects: aspects,
  rich: rich,
).toProviderJson();

YildiznameResolvedScope _resolve(
  Map<String, dynamic>? request, {
  String? artifactScope,
  String? artifactFidelity,
}) => YildiznameScopeResolver.resolveNarrative(
  artifactScope: artifactScope,
  artifactFidelity: artifactFidelity,
  request: request,
  result: artifactScope == null ? null : {'scope': artifactScope},
);

/// Consistent metadata for [scope] — the way a real accepted reading is stored.
YildiznameFactSnapshot _project(
  Map<String, dynamic>? request,
  YildiznameNarrativeScope scope, {
  String lang = 'tr',
}) {
  final resolved = _resolve(
    request,
    artifactScope: scope.wireName,
    artifactFidelity: switch (scope) {
      YildiznameNarrativeScope.legacy => 'tropicalSunSign',
      YildiznameNarrativeScope.reduced => 'reducedNatal',
      YildiznameNarrativeScope.full => 'fullNatalEphemeris',
    },
  );
  return YildiznameFactProjector.project(
    resolved: resolved,
    request: request,
    languageCode: lang,
  );
}

List<Map<String, dynamic>> _list(Map<String, dynamic> req, String key) => [
  for (final e in req[key] as List) e as Map<String, dynamic>,
];

Map<String, dynamic> _placement(Map<String, dynamic> req, String body) =>
    _list(req, 'placements').firstWhere((p) => p['body'] == body);

YildiznameDisplayFact? _fact(
  YildiznameFactSnapshot s,
  YildiznameFactSubject subject,
) {
  for (final f in s.facts) {
    if (f.subject == subject) return f;
  }
  return null;
}

List<YildiznameFactSubject> _subjects(List<YildiznameDisplayFact> facts) => [
  for (final f in facts) f.subject,
];

/// Every user-visible string the snapshot carries.
List<String> _texts(YildiznameFactSnapshot s) => [
  s.title,
  s.moreLabel,
  s.outerLabel,
  s.aspectsLabel,
  for (final f in s.facts) ...[f.label, f.value, ?f.detail, f.semanticsLabel],
  for (final a in s.aspects) ...[a.first, a.second, a.type, a.semanticsLabel],
  for (final b in s.balances) ...[b.label, b.value, b.semanticsLabel],
];

const _wire = [
  'sun',
  'moon',
  'mercury',
  'venus',
  'mars',
  'jupiter',
  'saturn',
  'uranus',
  'neptune',
  'pluto',
  'ascendant',
  'midheaven',
  'aries',
  'taurus',
  'gemini',
  'cancer',
  'leo',
  'virgo',
  'libra',
  'scorpio',
  'sagittarius',
  'capricorn',
  'aquarius',
  'pisces',
  'conjunction',
  'sextile',
  'square',
  'trine',
  'opposition',
  'factRef',
  'placement.',
  'angle.',
  'house.',
  'aspect.',
  'intervalStable',
  'exact',
  'ambiguous',
  'unavailable',
  'unsupported',
  'wholeSign',
  'omittedLayers',
  'calculationVersion',
  'fullNatalEphemeris',
  'reducedNatal',
  'tropicalSunSign',
  'star.fact.',
  'planet.',
  'zodiac.',
  'birth.element',
  'null',
];

void _expectNoRaw(YildiznameFactSnapshot s) {
  for (final t in _texts(s)) {
    for (final raw in _wire) {
      expect(t.contains(raw), isFalse, reason: '"$t" leaks "$raw"');
    }
  }
}

void main() {
  group('A — legacy: fact snapshot absent', () {
    test('legacy-scope request resolves and projects nothing', () {
      final s = _project(_req(_legacy), _legacy);
      expect(s.isEmpty, isTrue);
      expect(s, YildiznameFactSnapshot.empty);
    });

    test(
      'legacy live / unscoped / legacy artifact presentations are empty',
      () {
        final live = YildiznameResultPresentation.legacyLive(
          title: 't',
          sections: const [],
        );
        expect(live.factSnapshot.isEmpty, isTrue);
        final unscoped = YildiznameResultPresentation.unscoped(
          title: 't',
          sections: const [],
        );
        expect(unscoped.factSnapshot.isEmpty, isTrue);
      },
    );

    test(
      'a legacy request that claims rich structure still projects nothing',
      () {
        final req = _req(_full, rich: true);
        final resolved = _resolve(
          req,
          artifactScope: 'legacy',
          artifactFidelity: 'tropicalSunSign',
        );
        expect(resolved.scope, YildiznameResultScope.legacy);
        expect(
          YildiznameFactProjector.project(resolved: resolved, request: req),
          YildiznameFactSnapshot.empty,
        );
      },
    );
  });

  group('B — reduced with Sun only', () {
    test('a bare Sun cannot prove REDUCED (7B resolver) → no facts at all', () {
      final req = _req(_reduced);
      req['placements'] = [_placement(req, 'sun')];
      req['balances'] = <Object>[];
      final resolved = _resolve(
        req,
        artifactScope: 'reduced',
        artifactFidelity: 'reducedNatal',
      );
      expect(resolved.scope, YildiznameResultScope.legacy);
      final s = _project(req, _reduced);
      // Legacy-level evidence never becomes a natal fact snapshot; and were
      // it ever to render, nothing above the Sun sign could appear.
      expect(s, YildiznameFactSnapshot.empty);
    });

    test('Sun + one stable placement → Sun sign only, no precision', () {
      final s = _project(_req(_reduced), _reduced);
      final sun = _fact(s, YildiznameFactSubject.sun)!;
      expect(sun.value, 'Aslan');
      expect(sun.detail, isNull);
      expect(s.aspects, isEmpty);
      expect(s.balances, isEmpty);
    });
  });

  group('C — reduced with stable Sun / Moon / personal planets', () {
    Map<String, dynamic> stableReq() {
      final req = _req(_reduced);
      final base = _placement(req, 'sun');
      Map<String, dynamic> stable(String body, String sign) => {
        ...base,
        'factRef': 'placement.$body',
        'body': body,
        'sign': sign,
        'certainty': 'intervalStable',
      };
      req['placements'] = [
        stable('sun', 'leo'),
        stable('moon', 'cancer'),
        stable('mercury', 'virgo'),
        stable('venus', 'libra'),
        stable('mars', 'aries'),
      ];
      return req;
    }

    test('only actually stored placements render — sign level only', () {
      final s = _project(stableReq(), _reduced);
      expect(_subjects(s.primary), [
        YildiznameFactSubject.sun,
        YildiznameFactSubject.moon,
      ]);
      expect(_subjects(s.secondary), [
        YildiznameFactSubject.mercury,
        YildiznameFactSubject.venus,
        YildiznameFactSubject.mars,
      ]);
      expect(s.outer, isEmpty);
      for (final f in s.facts) {
        expect(f.detail, isNull, reason: 'reduced carries no precision');
      }
      expect(_fact(s, YildiznameFactSubject.moon)!.value, 'Yengeç');
      expect(_texts(s).any((t) => t.contains('°')), isFalse);
    });

    test('reduced never surfaces angles, aspects, balances or houses', () {
      final req = stableReq();
      req['angles'] = _list(_req(_full), 'angles');
      req['aspects'] = _list(_req(_full), 'aspects');
      req['houses'] = _list(_req(_full), 'houses');
      final s = _project(req, _reduced);
      expect(
        s.facts.map((f) => f.subject),
        isNot(contains(YildiznameFactSubject.ascendant)),
      );
      expect(
        s.facts.map((f) => f.subject),
        isNot(contains(YildiznameFactSubject.midheaven)),
      );
      expect(s.aspects, isEmpty);
      expect(s.balances, isEmpty);
    });

    test('the standard reduced fixture shows exactly its stored signs', () {
      final s = _project(_req(_reduced), _reduced);
      expect(_subjects(s.primary), [YildiznameFactSubject.sun]);
      expect(_subjects(s.secondary), [YildiznameFactSubject.mercury]);
      expect(_texts(s).any((t) => t.contains('°')), isFalse);
      expect(s.hasDeeper, isFalse);
    });
  });

  group('D — reduced request accidentally carrying precision', () {
    test(
      'degree / house / retrograde never display under a REDUCED ceiling',
      () {
        final req = _req(_reduced);
        for (final p in _list(req, 'placements')) {
          p['degreeWithinSign'] = 12.5;
          p['house'] = 4;
          p['retrograde'] = true;
        }
        final s = _project(req, _reduced);
        expect(s.facts, isNotEmpty);
        for (final f in s.facts) {
          expect(f.detail, isNull);
          expect(f.semanticsLabel.contains('°'), isFalse);
          expect(f.semanticsLabel.contains('geri'), isFalse);
        }
      },
    );
  });

  group('E — FULL complete', () {
    late YildiznameFactSnapshot s;
    setUp(() => s = _project(_req(_full, rich: true), _full));

    test('primary: Sun · Moon · Ascendant · Midheaven in that order', () {
      expect(_subjects(s.primary), [
        YildiznameFactSubject.sun,
        YildiznameFactSubject.moon,
        YildiznameFactSubject.ascendant,
        YildiznameFactSubject.midheaven,
      ]);
    });

    test('secondary: Mercury · Venus · Mars', () {
      expect(_subjects(s.secondary), [
        YildiznameFactSubject.mercury,
        YildiznameFactSubject.venus,
        YildiznameFactSubject.mars,
      ]);
    });

    test('deeper: outer planets in order, tightest aspects, balances', () {
      expect(_subjects(s.outer), [
        YildiznameFactSubject.jupiter,
        YildiznameFactSubject.saturn,
        YildiznameFactSubject.uranus,
        YildiznameFactSubject.neptune,
        YildiznameFactSubject.pluto,
      ]);
      expect(s.aspects, hasLength(YildiznameFactProjector.maxAspects));
      expect(s.balances, hasLength(2));
      expect(s.hasDeeper, isTrue);
    });

    test('values: localized sign, whole degree, house, retrograde', () {
      final sun = _fact(s, YildiznameFactSubject.sun)!;
      expect(sun.label, 'Güneş');
      expect(sun.value, 'Aslan');
      expect(sun.detail, '22° · 10. ev');
      final asc = _fact(s, YildiznameFactSubject.ascendant)!;
      expect(asc.value, 'Akrep');
      expect(asc.detail, '11°');
      final mc = _fact(s, YildiznameFactSubject.midheaven)!;
      expect(mc.label, 'Gökyüzü Ortası');
      expect(mc.detail, '19°');
      final mercury = _fact(s, YildiznameFactSubject.mercury)!;
      expect(mercury.detail, '14° · 11. ev · geri hareket');
      final venus = _fact(s, YildiznameFactSubject.venus)!;
      expect(venus.detail, '3° · 12. ev');
    });

    test('aspects are ordered by orb, bodies in fixed order, capped', () {
      expect(s.aspects.map((a) => '${a.first}|${a.second}|${a.type}'), [
        'Merkür|Venüs|Kavuşum',
        'Ay|Satürn|Karşıt',
        'Güneş|Ay|Üçgen',
        'Venüs|Jüpiter|Sekstil',
        'Güneş|Mars|Kare',
      ]);
    });

    test('balances: dominant element and quality, localized', () {
      expect(s.balances.map((b) => '${b.label}: ${b.value}'), [
        'Baskın element: Ateş',
        'Baskın nitelik: Sabit',
      ]);
    });

    test('no raw identifier reaches any string', () => _expectNoRaw(s));
  });

  group('F/G — FULL without Moon / Ascendant: absence means omission', () {
    test('F — no Moon placement → no Moon fact, nothing in its place', () {
      final req = _req(_full);
      req['placements'] = [
        for (final p in _list(req, 'placements'))
          if (p['body'] != 'moon') p,
      ];
      final s = _project(req, _full);
      expect(_fact(s, YildiznameFactSubject.moon), isNull);
      expect(_subjects(s.primary), [
        YildiznameFactSubject.sun,
        YildiznameFactSubject.ascendant,
        YildiznameFactSubject.midheaven,
      ]);
      _expectNoRaw(s);
    });

    test('G — no Ascendant → no Ascendant fact, no placeholder', () {
      final s = _project(_req(_full, ascendant: false), _full);
      expect(_fact(s, YildiznameFactSubject.ascendant), isNull);
      expect(_subjects(s.primary), [
        YildiznameFactSubject.sun,
        YildiznameFactSubject.moon,
        YildiznameFactSubject.midheaven,
      ]);
    });

    test('no Midheaven → none rendered', () {
      final s = _project(_req(_full, midheaven: false), _full);
      expect(_fact(s, YildiznameFactSubject.midheaven), isNull);
      expect(_subjects(s.primary), [
        YildiznameFactSubject.sun,
        YildiznameFactSubject.moon,
        YildiznameFactSubject.ascendant,
      ]);
    });

    test('no placeholder strings ever appear', () {
      final s = _project(
        _req(_full, ascendant: false, midheaven: false, houses: false),
        _full,
      );
      for (final t in _texts(s)) {
        expect(t.trim(), isNot(equals('—')));
        expect(t.contains('Bilinmiyor'), isFalse);
        expect(t.contains('Unknown'), isFalse);
      }
    });
  });

  group('H/I — FULL without houses / aspects', () {
    test('H — no houses → no house detail anywhere', () {
      final s = _project(_req(_full, houses: false), _full);
      for (final f in s.facts) {
        expect(f.detail?.contains('ev') ?? false, isFalse);
      }
      expect(_fact(s, YildiznameFactSubject.sun)!.detail, '22°');
    });

    test('I — no aspects → no aspect layer', () {
      final s = _project(_req(_full, aspects: false, rich: true), _full);
      expect(s.aspects, isEmpty);
    });
  });

  group('J/K — present AND listed omitted: the omission wins', () {
    test('J — Ascendant object present, omittedLayers has ascendant', () {
      final req = _req(_full);
      (req['omittedLayers'] as List).add('ascendant');
      final s = _project(req, _full);
      expect(_fact(s, YildiznameFactSubject.ascendant), isNull);
      expect(_fact(s, YildiznameFactSubject.midheaven), isNotNull);
    });

    test('J — Midheaven likewise', () {
      final req = _req(_full);
      (req['omittedLayers'] as List).add('midheaven');
      final s = _project(req, _full);
      expect(_fact(s, YildiznameFactSubject.midheaven), isNull);
      expect(_fact(s, YildiznameFactSubject.ascendant), isNotNull);
    });

    test('K — houses present, omittedLayers has houses → no house detail', () {
      final req = _req(_full, rich: true);
      (req['omittedLayers'] as List).add('houses');
      final s = _project(req, _full);
      for (final f in s.facts) {
        expect(f.detail?.contains('ev') ?? false, isFalse, reason: f.label);
      }
      expect(_fact(s, YildiznameFactSubject.sun)!.detail, '22°');
    });

    test('aspects present, omittedLayers has aspects → no aspect layer', () {
      final req = _req(_full, rich: true);
      (req['omittedLayers'] as List).add('aspects');
      expect(_project(req, _full).aspects, isEmpty);
    });
  });

  group('L — resolved scope is the ceiling (downgrade honored)', () {
    void expectReducedCeiling(YildiznameFactSnapshot s) {
      expect(_fact(s, YildiznameFactSubject.ascendant), isNull);
      expect(_fact(s, YildiznameFactSubject.midheaven), isNull);
      expect(s.aspects, isEmpty);
      expect(s.balances, isEmpty);
      for (final f in s.facts) {
        expect(f.detail, isNull, reason: f.label);
      }
      expect(_texts(s).any((t) => t.contains('°')), isFalse);
      expect(_texts(s).any((t) => t.contains('ev')), isFalse);
    }

    test('rich FULL request + reducedNatal fidelity → REDUCED behavior', () {
      final req = _req(_full, rich: true);
      final resolved = _resolve(
        req,
        artifactScope: 'full',
        artifactFidelity: 'reducedNatal',
      );
      expect(resolved.scope, isNot(YildiznameResultScope.full));
      expectReducedCeiling(
        YildiznameFactProjector.project(resolved: resolved, request: req),
      );
    });

    test('rich FULL request + artifact scope reduced → REDUCED behavior', () {
      final req = _req(_full, rich: true);
      final resolved = _resolve(
        req,
        artifactScope: 'reduced',
        artifactFidelity: 'reducedNatal',
      );
      expect(resolved.scope, YildiznameResultScope.reduced);
      expectReducedCeiling(
        YildiznameFactProjector.project(resolved: resolved, request: req),
      );
    });

    test('rich FULL request + omitted exactDegrees → no degrees', () {
      final req = _req(_full, rich: true);
      (req['omittedLayers'] as List).add('exactDegrees');
      final resolved = _resolve(
        req,
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
      );
      expect(resolved.scope, isNot(YildiznameResultScope.full));
      expectReducedCeiling(
        YildiznameFactProjector.project(resolved: resolved, request: req),
      );
    });

    test('rich FULL request + conflicting scope markers → no FULL facts', () {
      final req = _req(_full, rich: true);
      req['scope'] = 'reduced';
      final resolved = _resolve(
        req,
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
      );
      expect(resolved.scope, isNot(YildiznameResultScope.full));
      expectReducedCeiling(
        YildiznameFactProjector.project(resolved: resolved, request: req),
      );
    });

    test('rich structure never upgrades a reduced claim', () {
      final req = _req(_reduced);
      final rich = _req(_full, rich: true);
      req['angles'] = rich['angles'];
      req['aspects'] = rich['aspects'];
      req['houses'] = rich['houses'];
      final s = _project(req, _reduced);
      expect(s.facts, isNotEmpty, reason: 'the stored reduced signs remain');
      expectReducedCeiling(s);
    });
  });

  group('M — untrusted certainty never renders', () {
    for (final bad in const [
      'ambiguous',
      'unavailable',
      'unsupported',
      'guess',
      '',
      'EXACT',
    ]) {
      test('placement certainty "$bad" (FULL) is dropped', () {
        final req = _req(_full);
        _placement(req, 'moon')['certainty'] = bad;
        final s = _project(req, _full);
        expect(_fact(s, YildiznameFactSubject.moon), isNull);
        expect(_fact(s, YildiznameFactSubject.sun), isNotNull);
      });

      test('placement certainty "$bad" (REDUCED) is dropped', () {
        final req = _req(_reduced);
        _placement(req, 'mercury')['certainty'] = bad;
        final s = _project(req, _reduced);
        expect(_fact(s, YildiznameFactSubject.mercury), isNull);
      });

      test('angle certainty "$bad" is dropped', () {
        final req = _req(_full);
        _list(
          req,
          'angles',
        ).firstWhere((a) => a['kind'] == 'ascendant')['certainty'] = bad;
        final s = _project(req, _full);
        expect(_fact(s, YildiznameFactSubject.ascendant), isNull);
      });
    }

    test('non-string / missing certainty is dropped', () {
      final req = _req(_full);
      _placement(req, 'moon')['certainty'] = 7;
      _placement(req, 'sun').remove('certainty');
      final s = _project(req, _full);
      expect(_fact(s, YildiznameFactSubject.moon), isNull);
      expect(_fact(s, YildiznameFactSubject.sun), isNull);
    });

    test('FULL intervalStable placement shows its sign, never a degree', () {
      final req = _req(_full);
      final moon = _placement(req, 'moon');
      moon['certainty'] = 'intervalStable';
      final s = _project(req, _full);
      final f = _fact(s, YildiznameFactSubject.moon)!;
      expect(f.value, 'Boğa');
      expect(f.detail, isNull);
    });

    test('an exact claim under a REDUCED ceiling is not trusted', () {
      final req = _req(_reduced);
      _placement(req, 'sun')['certainty'] = 'exact';
      expect(_fact(_project(req, _reduced), YildiznameFactSubject.sun), isNull);
    });
  });

  group('N/O/P — unknown identifiers vanish, never render raw', () {
    test('N — unknown body is dropped', () {
      final req = _req(_full);
      (req['placements'] as List).add({
        'factRef': 'placement.chiron',
        'body': 'chiron',
        'sign': 'leo',
        'certainty': 'exact',
        'degreeWithinSign': 4.0,
      });
      final s = _project(req, _full);
      expect(s.facts, hasLength(_project(_req(_full), _full).facts.length));
      for (final t in _texts(s)) {
        expect(t.toLowerCase().contains('chiron'), isFalse);
      }
    });

    test('N — angle pretending to be a body is dropped', () {
      final req = _req(_full);
      (req['placements'] as List).add({
        'factRef': 'placement.ascendant',
        'body': 'ascendant',
        'sign': 'leo',
        'certainty': 'exact',
      });
      final s = _project(req, _full);
      final asc = _fact(s, YildiznameFactSubject.ascendant)!;
      expect(asc.value, 'Akrep', reason: 'stored angle wins, not the body row');
    });

    test('O — unknown / malformed sign drops the fact', () {
      for (final bad in <Object?>['ophiuchus', 'LEO', '', null, 3, 'Leo ']) {
        final req = _req(_full);
        _placement(req, 'moon')['sign'] = bad;
        final s = _project(req, _full);
        expect(_fact(s, YildiznameFactSubject.moon), isNull, reason: '$bad');
        _expectNoRaw(s);
      }
    });

    test('O — unknown angle sign drops the angle', () {
      final req = _req(_full);
      _list(req, 'angles').first['sign'] = 'ophiuchus';
      final s = _project(req, _full);
      expect(_fact(s, YildiznameFactSubject.ascendant), isNull);
    });

    test('P — unknown aspect type is dropped', () {
      final req = _req(_full);
      _list(req, 'aspects').first['type'] = 'quincunx';
      final s = _project(req, _full);
      expect(s.aspects, isEmpty);
      for (final t in _texts(s)) {
        expect(t.toLowerCase().contains('quincunx'), isFalse);
      }
    });

    test('aspect with an unknown or undisplayed body is dropped', () {
      final req = _req(_full);
      _list(req, 'aspects').first['bodyB'] = 'chiron';
      expect(_project(req, _full).aspects, isEmpty);
      final req2 = _req(_full);
      _list(req2, 'aspects').first['bodyB'] = 'mars'; // mars not stored
      expect(_project(req2, _full).aspects, isEmpty);
    });

    test('aspect between a body and itself is dropped', () {
      final req = _req(_full);
      _list(req, 'aspects').first['bodyB'] = 'sun';
      _list(req, 'aspects').first['bodyA'] = 'sun';
      expect(_project(req, _full).aspects, isEmpty);
    });
  });

  group('Q/R — degree: real 0.0 is real; invalid is omitted', () {
    String? sunDetail(Object? degree, {bool omit = false}) {
      final req = _req(_full);
      final sun = _placement(req, 'sun');
      sun['house'] = null;
      if (omit) {
        sun.remove('degreeWithinSign');
      } else {
        sun['degreeWithinSign'] = degree;
      }
      sun.remove('house');
      sun.remove('retrograde');
      return _fact(_project(req, _full), YildiznameFactSubject.sun)!.detail;
    }

    test('Q — a genuine stored 0.0 renders as 0°', () {
      expect(sunDetail(0.0), '0°');
      expect(sunDetail(0), '0°');
    });

    test('absent degree renders no degree at all (no synthetic 0°)', () {
      expect(sunDetail(null, omit: true), isNull);
    });

    test('R — NaN / infinity / negative / >= 30 / wrong type are omitted', () {
      for (final bad in <Object?>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -0.1,
        -5,
        30,
        30.0,
        45.5,
        360,
        '12.5',
        true,
        <Object>[],
      ]) {
        expect(sunDetail(bad), isNull, reason: '$bad');
      }
    });

    test('whole degrees are truncated, never rounded across a sign', () {
      expect(sunDetail(22.4), '22°');
      expect(sunDetail(22.6), '22°');
      expect(sunDetail(29.99), '29°');
      expect(sunDetail(29.9999999), '29°');
      expect(sunDetail(0.4), '0°');
      expect(sunDetail(1.0), '1°');
    });

    test('degree formatting is locale-independent and deterministic', () {
      final req = _req(_full);
      final tr = _fact(_project(req, _full), YildiznameFactSubject.ascendant)!;
      final en = _fact(
        _project(req, _full, lang: 'en'),
        YildiznameFactSubject.ascendant,
      )!;
      final ru = _fact(
        _project(req, _full, lang: 'ru'),
        YildiznameFactSubject.ascendant,
      )!;
      expect(tr.detail, '11°');
      expect(en.detail, '11°');
      expect(ru.detail, '11°');
    });

    test('invalid house numbers are omitted without hiding the degree', () {
      for (final bad in <Object?>[0, 13, -1, 2.5, double.nan, '4', null]) {
        final req = _req(_full);
        _placement(req, 'sun')['house'] = bad;
        final f = _fact(_project(req, _full), YildiznameFactSubject.sun)!;
        expect(f.detail, '22°', reason: '$bad');
      }
    });

    test(
      'retrograde is shown only for planets that can be, only when exact',
      () {
        final req = _req(_full, rich: true);
        _placement(req, 'sun')['retrograde'] = true;
        _placement(req, 'moon')['retrograde'] = true;
        final s = _project(req, _full);
        expect(
          _fact(s, YildiznameFactSubject.sun)!.detail!.contains('geri'),
          isFalse,
        );
        expect(
          _fact(s, YildiznameFactSubject.moon)!.detail!.contains('geri'),
          isFalse,
        );
        expect(
          _fact(s, YildiznameFactSubject.mercury)!.detail!.contains('geri'),
          isTrue,
        );
        // non-bool retrograde values never count.
        final req2 = _req(_full, rich: true);
        _placement(req2, 'mercury')['retrograde'] = 'true';
        expect(
          _fact(
            _project(req2, _full),
            YildiznameFactSubject.mercury,
          )!.detail!.contains('geri'),
          isFalse,
        );
      },
    );
  });

  group('S — old artifact / no request', () {
    test('null request projects an empty snapshot', () {
      expect(_project(null, _full), YildiznameFactSnapshot.empty);
      expect(
        YildiznameFactProjector.project(
          resolved: YildiznameResolvedScope.legacy,
          request: null,
        ),
        YildiznameFactSnapshot.empty,
      );
    });

    test('artifact without a request: empty facts, prose still opens', () {
      final base = yildiznameFixtureNarrativeArtifact(scope: _full);
      final payload = Map<String, dynamic>.from(base.payload)
        ..remove('request');
      final p = YildiznameArtifactPresentation.of(
        yildiznameFixtureRawNarrativeArtifact(
          payload: payload,
          scope: 'full',
          fidelity: 'fullNatalEphemeris',
        ),
        chromeLocale: 'tr',
      );
      expect(p.factSnapshot, YildiznameFactSnapshot.empty);
      expect(p.sections, isNotEmpty);
      expect(p.scopeDisclosure, isNotNull);
    });

    test('malformed structures never crash and never fabricate', () {
      final shapes = <String, Object?>{
        'placements not a list': 'sun',
        'placements null': null,
        'entries not maps': [1, 'sun', null, true],
        'empty': <Object>[],
      };
      shapes.forEach((name, value) {
        final req = _req(_full);
        req['placements'] = value;
        req['angles'] = value;
        req['aspects'] = value;
        req['balances'] = value;
        final s = _project(req, _full);
        expect(s.isEmpty, isTrue, reason: name);
      });
      final req = _req(_full)
        ..['placements'] = 5
        ..['angles'] = {'kind': 'ascendant'};
      expect(() => _project(req, _full), returnsNormally);
    });

    test('entries with non-string keys are skipped, never thrown on', () {
      final req = _req(_full);
      req['placements'] = <Object?>[
        ...(req['placements'] as List),
        <Object, Object>{1: 'sun', 'body': 'mars'},
      ];
      req['aspects'] = <Object?>[
        ...(req['aspects'] as List),
        <Object, Object>{2: 'x'},
      ];
      final base = _project(_req(_full), _full);
      expect(() => _project(req, _full), returnsNormally);
      expect(_project(req, _full), base);
    });

    test('a request with no arrays projects an empty snapshot', () {
      final req = <String, dynamic>{
        'scope': 'full',
        'fidelity': 'fullNatalEphemeris',
      };
      expect(_project(req, _full).isEmpty, isTrue);
    });
  });

  group('T — the current profile can never enrich an old artifact', () {
    test('projection is a pure function of the stored request', () {
      // The projector takes no profile, chart repository or clock — same
      // request, same snapshot, regardless of what the user has today.
      final req = _req(_reduced);
      final a = _project(req, _reduced);
      final b = _project(_req(_reduced), _reduced);
      expect(a, b);
      expect(_texts(a).any((t) => t.contains('°')), isFalse);
      expect(a.aspects, isEmpty);
    });
  });

  group('U — live / artifact parity', () {
    for (final scope in const [_reduced, _full]) {
      test('${scope.wireName}: narrativeLive == artifact projection', () {
        final artifact = yildiznameFixtureNarrativeArtifact(
          scope: scope,
          rich: scope == _full,
        );
        final request = yildiznameFixtureRequest(
          scope: scope,
          rich: scope == _full,
        );
        final result = yildiznameFixtureResult(scope: scope);
        final fromArtifact = YildiznameArtifactPresentation.of(
          artifact,
          chromeLocale: 'tr',
        );
        final live = YildiznameArtifactPresentation.narrativeLive(
          request: request,
          result: result,
          chromeLocale: 'tr',
        );
        expect(live.factSnapshot, fromArtifact.factSnapshot);
        expect(live.factSnapshot.isNotEmpty, isTrue);
        expect(live.scope, fromArtifact.scope);
        expect(live.scopeDisclosure, fromArtifact.scopeDisclosure);
        expect(live.source, YildiznameResultSource.narrativeLive);
        expect(fromArtifact.source, YildiznameResultSource.narrativeArtifact);
      });
    }
  });

  group('V — localization (TR / EN / RU)', () {
    const expected = {
      'tr': {
        'title': 'Doğum göğün',
        'sun': 'Güneş',
        'moon': 'Ay',
        'asc': 'Yükselen',
        'mc': 'Gökyüzü Ortası',
        'leo': 'Aslan',
        'taurus': 'Boğa',
        'scorpio': 'Akrep',
        'house': '10. ev',
      },
      'en': {
        'title': 'Your birth sky',
        'sun': 'Sun',
        'moon': 'Moon',
        'asc': 'Rising',
        'mc': 'Midheaven',
        'leo': 'Leo',
        'taurus': 'Taurus',
        'scorpio': 'Scorpio',
        'house': 'House 10',
      },
      'ru': {
        'title': 'Твоё небо рождения',
        'sun': 'Солнце',
        'moon': 'Луна',
        'asc': 'Асцендент',
        'mc': 'Середина неба',
        'leo': 'Лев',
        'taurus': 'Телец',
        'scorpio': 'Скорпион',
        'house': '10-й дом',
      },
    };

    expected.forEach((lang, want) {
      test('$lang: labels, signs and chrome are localized', () {
        final s = _project(_req(_full, rich: true), _full, lang: lang);
        expect(s.title, want['title']);
        final sun = _fact(s, YildiznameFactSubject.sun)!;
        expect(sun.label, want['sun']);
        expect(sun.value, want['leo']);
        expect(sun.detail, contains(want['house']!));
        expect(_fact(s, YildiznameFactSubject.moon)!.label, want['moon']);
        expect(_fact(s, YildiznameFactSubject.moon)!.value, want['taurus']);
        final asc = _fact(s, YildiznameFactSubject.ascendant)!;
        expect(asc.label, want['asc']);
        expect(asc.value, want['scorpio']);
        expect(_fact(s, YildiznameFactSubject.midheaven)!.label, want['mc']);
      });

      test('$lang: no key, wire value or raw identifier leaks', () {
        _expectNoRaw(_project(_req(_full, rich: true), _full, lang: lang));
        _expectNoRaw(_project(_req(_reduced), _reduced, lang: lang));
      });
    });

    test('an unknown language falls back to a supported one, never a key', () {
      final s = _project(_req(_full), _full, lang: 'xx');
      _expectNoRaw(s);
      expect(s.title, isNotEmpty);
    });
  });

  group('W — internal identifier scan', () {
    test('every string of every scope/locale is free of wire identifiers', () {
      for (final lang in const ['tr', 'en', 'ru']) {
        for (final scope in const [_reduced, _full]) {
          _expectNoRaw(
            _project(_req(scope, rich: scope == _full), scope, lang: lang),
          );
        }
      }
    });

    test('theme / prose text never becomes a fact', () {
      final req = _req(_reduced);
      req['discoveryThemes'] = [
        {'themeRef': 'theme.0', 'label': 'Mars Koç 12° 4. ev'},
      ];
      final s = _project(req, _reduced);
      expect(_fact(s, YildiznameFactSubject.mars), isNull);
      expect(_texts(s).any((t) => t.contains('12°')), isFalse);
    });

    test('result prose containing fact-like text creates no fact', () {
      final base = yildiznameFixtureNarrativeArtifact(
        scope: _reduced,
        summary: 'Mars Koç burcunda 12° ve Ay 4. evde, Yükselen Akrep.',
      );
      final p = YildiznameArtifactPresentation.of(base, chromeLocale: 'tr');
      expect(_fact(p.factSnapshot, YildiznameFactSubject.mars), isNull);
      expect(_fact(p.factSnapshot, YildiznameFactSubject.moon), isNull);
      expect(_fact(p.factSnapshot, YildiznameFactSubject.ascendant), isNull);
    });
  });

  group('X — deterministic projection', () {
    test('equal input → equal snapshot, hash and order', () {
      final a = _project(_req(_full, rich: true), _full);
      final b = _project(_req(_full, rich: true), _full);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(_texts(a), _texts(b));
    });

    test('request array order never changes the snapshot', () {
      final base = _project(_req(_full, rich: true), _full);
      final shuffled = _req(_full, rich: true);
      for (final key in const ['placements', 'angles', 'aspects', 'balances']) {
        shuffled[key] = (shuffled[key] as List).reversed.toList();
      }
      expect(_project(shuffled, _full), base);
      final rotated = _req(_full, rich: true);
      final p = (rotated['placements'] as List);
      rotated['placements'] = [...p.skip(3), ...p.take(3)];
      expect(_project(rotated, _full), base);
    });

    test('unknown facts never reorder known ones', () {
      final base = _project(_req(_full, rich: true), _full);
      final noisy = _req(_full, rich: true);
      final p = noisy['placements'] as List;
      p.insert(0, {'body': 'chiron', 'sign': 'leo', 'certainty': 'exact'});
      p.insert(3, {'body': 'lilith', 'sign': 'leo', 'certainty': 'exact'});
      p.add({'body': 'moon', 'sign': 'ophiuchus', 'certainty': 'exact'});
      // A second, contradictory Moon row removes the Moon entirely — but the
      // rest keep their order.
      final s = _project(noisy, _full);
      expect(_subjects(s.secondary), _subjects(base.secondary));
      expect(_subjects(s.outer), _subjects(base.outer));
      expect(_fact(s, YildiznameFactSubject.moon), isNull);
    });

    test('a body stated twice is contradictory evidence and vanishes', () {
      final req = _req(_full);
      (req['placements'] as List).add({
        'factRef': 'placement.sun',
        'body': 'sun',
        'sign': 'aries',
        'certainty': 'exact',
        'degreeWithinSign': 1.0,
      });
      expect(_fact(_project(req, _full), YildiznameFactSubject.sun), isNull);
    });

    test('a factRef naming a different body contradicts the fact', () {
      final req = _req(_full);
      _placement(req, 'moon')['factRef'] = 'placement.sun';
      expect(_fact(_project(req, _full), YildiznameFactSubject.moon), isNull);
    });

    test('an angle whose kind and factRef disagree is dropped', () {
      final req = _req(_full);
      _list(req, 'angles').first['factRef'] = 'angle.midheaven';
      final s = _project(req, _full);
      expect(_fact(s, YildiznameFactSubject.ascendant), isNull);
    });

    test('aspect ties order deterministically', () {
      final req = _req(_full, rich: true);
      for (final a in _list(req, 'aspects')) {
        a['orb'] = 2.0;
      }
      final one = _project(req, _full);
      final reversed = _req(_full, rich: true);
      for (final a in _list(reversed, 'aspects')) {
        a['orb'] = 2.0;
      }
      reversed['aspects'] = (reversed['aspects'] as List).reversed.toList();
      expect(_project(reversed, _full), one);
    });

    test('aspect orb is validated but never displayed', () {
      final req = _req(_full);
      for (final bad in <Object?>[double.nan, -1.0, '2', null]) {
        _list(req, 'aspects').first['orb'] = bad;
        expect(_project(req, _full).aspects, isEmpty, reason: '$bad');
      }
      final s = _project(_req(_full), _full);
      for (final a in s.aspects) {
        expect(a.semanticsLabel.contains('2.1'), isFalse);
      }
    });

    test('duplicate aspect pairs collapse to one', () {
      final req = _req(_full);
      final a = _list(req, 'aspects').first;
      (req['aspects'] as List).add({
        ...a,
        'bodyA': a['bodyB'],
        'bodyB': a['bodyA'],
      });
      expect(_project(req, _full).aspects, hasLength(1));
    });
  });

  group('balances fail closed', () {
    test('a tied "dominant" is not a claim', () {
      final req = _req(_full);
      _list(req, 'balances')[0]['counts'] = {
        'fire': 3,
        'earth': 3,
        'air': 1,
        'water': 0,
      };
      final s = _project(req, _full);
      expect(s.balances.map((b) => b.label), ['Baskın nitelik']);
    });

    test('a dominant that is not the maximum is rejected', () {
      final req = _req(_full);
      _list(req, 'balances')[0]['dominant'] = 'water';
      expect(_project(req, _full).balances.map((b) => b.label), [
        'Baskın nitelik',
      ]);
    });

    test('unknown dominant / malformed counts are rejected', () {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (b) => b['dominant'] = 'plasma',
        (b) => b['dominant'] = null,
        (b) => b['counts'] = 'fire',
        (b) => b['counts'] = {'fire': double.nan, 'earth': 1},
        (b) => b['counts'] = {'fire': -2, 'earth': 1},
        (b) => b['counts'] = {'fire': 'x'},
        (b) => b['counts'] = <String, Object>{},
      ]) {
        final req = _req(_full);
        mutate(_list(req, 'balances')[0]);
        expect(
          _project(req, _full).balances.map((b) => b.label),
          isNot(contains('Baskın element')),
        );
      }
    });

    test('the same balance twice is contradictory and dropped', () {
      final req = _req(_full);
      (req['balances'] as List).add(_list(req, 'balances')[0]);
      expect(
        _project(req, _full).balances.map((b) => b.label),
        isNot(contains('Baskın element')),
      );
    });

    test('balances never appear under REDUCED', () {
      expect(_project(_req(_reduced), _reduced).balances, isEmpty);
    });
  });

  group('house system and orb are not surface facts', () {
    test('house system wire value never leaks', () {
      final s = _project(_req(_full, rich: true), _full);
      expect(_texts(s).any((t) => t.contains('wholeSign')), isFalse);
      expect(_texts(s).any((t) => t.contains('Whole')), isFalse);
    });
  });

  group('immutability', () {
    test('projection mutates neither request nor artifact', () {
      final artifact = yildiznameFixtureNarrativeArtifact(
        scope: _full,
        rich: true,
      );
      final before = _deepCopy(artifact.payload);
      final hash = artifact.contentHash;
      final semantic = artifact.semanticDedupeKey;
      final scope = artifact.scope;
      final fidelity = artifact.fidelity;
      final p1 = YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'tr',
      );
      final p2 = YildiznameArtifactPresentation.of(
        artifact,
        chromeLocale: 'en',
      );
      expect(p1.factSnapshot.isNotEmpty, isTrue);
      expect(p2.factSnapshot.isNotEmpty, isTrue);
      expect(artifact.payload, before);
      expect(artifact.contentHash, hash);
      expect(artifact.semanticDedupeKey, semantic);
      expect(artifact.scope, scope);
      expect(artifact.fidelity, fidelity);
      YildiznameArtifactIntegrity.verify(artifact);
    });

    test('the projector does not mutate the request map it is given', () {
      final req = _req(_full, rich: true);
      final before = _deepCopy(req);
      _project(req, _full);
      _project(req, _reduced);
      expect(req, before);
    });

    test('snapshot lists cannot be used to reach the request', () {
      final s = _project(_req(_full, rich: true), _full);
      expect(s.primary, isA<List<YildiznameDisplayFact>>());
      // A display fact carries strings only — no maps, no wire values.
      for (final f in s.facts) {
        expect(f.label, isA<String>());
        expect(f.value, isA<String>());
      }
    });
  });
}

Object? _deepCopy(Object? v) {
  if (v is Map) {
    return {for (final e in v.entries) e.key: _deepCopy(e.value)};
  }
  if (v is List) return [for (final e in v) _deepCopy(e)];
  return v;
}
