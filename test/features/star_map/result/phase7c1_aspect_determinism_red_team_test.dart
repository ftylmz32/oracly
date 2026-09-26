/// Phase 7C.1 — aspect duplicate conflict + order independence red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_projector.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_snapshot.dart';
import 'package:oracly_new/features/star_map/result/yildizname_scope_resolver.dart';

import '../../../support/yildizname_result_fixtures.dart';

Map<String, dynamic> _rich() => yildiznameFixtureRequest(
      scope: YildiznameNarrativeScope.full,
      rich: true,
    ).toProviderJson();

YildiznameFactSnapshot _project(Map<String, dynamic> request) =>
    YildiznameFactProjector.project(
      resolved: YildiznameScopeResolver.resolveNarrative(
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
        request: request,
        result: const {'scope': 'full'},
      ),
      request: request,
      languageCode: 'tr',
    );

List<Map<String, dynamic>> _rows(Map<String, dynamic> req) => [
      for (final e in req['aspects'] as List) e as Map<String, dynamic>,
    ];

List<String> _keys(YildiznameFactSnapshot s) => [
      for (final a in s.aspects) '${a.first}|${a.second}|${a.type}',
    ];

bool _hasSunMars(YildiznameFactSnapshot s) =>
    _keys(s).any((k) => k.contains('Güneş') && k.contains('Mars'));

Map<String, dynamic> _conflict({required bool reverseFirst}) {
  final req = _rich();
  final rows = _rows(req);
  final a = <String, dynamic>{
    'factRef': 'aspect.sun.mars.square',
    'bodyA': 'sun',
    'bodyB': 'mars',
    'type': 'square',
    'orb': 4.8,
  };
  final b = <String, dynamic>{
    'factRef': 'aspect.mars.sun.square',
    'bodyA': 'mars',
    'bodyB': 'sun',
    'type': 'square',
    'orb': 0.1,
  };
  rows.removeWhere(
    (r) =>
        (r['bodyA'] == 'sun' && r['bodyB'] == 'mars') ||
        (r['bodyA'] == 'mars' && r['bodyB'] == 'sun'),
  );
  req['aspects'] = reverseFirst ? [b, a, ...rows] : [a, b, ...rows];
  return req;
}

void main() {
  test('A identical orb duplicates → one aspect', () {
    final req = _rich();
    final rows = _rows(req);
    final base = Map<String, dynamic>.from(rows.first);
    rows.add({
      ...base,
      'bodyA': base['bodyB'],
      'bodyB': base['bodyA'],
      'factRef': 'aspect.${base['bodyB']}.${base['bodyA']}.${base['type']}',
    });
    req['aspects'] = rows;
    expect(
      _keys(_project(req))
          .where((k) => k.contains('Merkür') && k.contains('Venüs')),
      hasLength(1),
    );
  });

  test('B reversed bodies same orb → one aspect', () {
    final req = _rich();
    final rows = _rows(req);
    final sunMars =
        rows.firstWhere((r) => r['bodyA'] == 'sun' && r['bodyB'] == 'mars');
    rows.add({
      'factRef': 'aspect.mars.sun.square',
      'bodyA': 'mars',
      'bodyB': 'sun',
      'type': 'square',
      'orb': sunMars['orb'],
    });
    req['aspects'] = rows;
    expect(
      _keys(_project(req))
          .where((k) => k.contains('Güneş') && k.contains('Mars')),
      hasLength(1),
    );
  });

  test('C conflicting orbs → entire canonical aspect dropped', () {
    expect(_hasSunMars(_project(_conflict(reverseFirst: false))), isFalse);
  });

  test('D conflicting reverse → identical snapshot + hash', () {
    final a = _project(_conflict(reverseFirst: false));
    final b = _project(_conflict(reverseFirst: true));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(_keys(a), _keys(b));
  });

  test('E top-5 boundary stable after reorder; Pluto fills vacated slot', () {
    final a = _project(_conflict(reverseFirst: false));
    final b = _project(_conflict(reverseFirst: true));
    expect(a.aspects, hasLength(YildiznameFactProjector.maxAspects));
    expect(_keys(a), _keys(b));
    expect(_keys(a).any((k) => k.contains('Plüton')), isTrue);
  });

  test('F wrong-ref duplicate ignored; valid row survives', () {
    final req = _rich();
    final rows = _rows(req);
    rows.add({
      'factRef': 'aspect.wrong.ref.square',
      'bodyA': 'mars',
      'bodyB': 'sun',
      'type': 'square',
      'orb': 0.05,
    });
    req['aspects'] = rows;
    expect(
      _keys(_project(req))
          .where((k) => k.contains('Güneş') && k.contains('Mars')),
      hasLength(1),
    );
  });

  test('G two valid conflicting orbs → fail closed as one group', () {
    expect(_hasSunMars(_project(_conflict(reverseFirst: false))), isFalse);
  });
}
