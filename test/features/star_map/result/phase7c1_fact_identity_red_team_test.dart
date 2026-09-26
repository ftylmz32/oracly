/// Phase 7C.1 — placement / angle / aspect factRef identity red-team.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_projector.dart';
import 'package:oracly_new/features/star_map/result/yildizname_fact_snapshot.dart';
import 'package:oracly_new/features/star_map/result/yildizname_scope_resolver.dart';

import '../../../support/yildizname_result_fixtures.dart';

Map<String, dynamic> _req() =>
    yildiznameFixtureRequest(scope: YildiznameNarrativeScope.full)
        .toProviderJson();

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

void main() {
  group('placement identity', () {
    test('A correct ref renders', () {
      expect(_fact(_project(_req()), YildiznameFactSubject.moon), isNotNull);
    });
    test('B wrong body in ref → absent', () {
      final req = _req();
      _placement(req, 'moon')['factRef'] = 'placement.sun';
      expect(_fact(_project(req), YildiznameFactSubject.moon), isNull);
    });
    test('C missing factRef → absent', () {
      final req = _req();
      _placement(req, 'moon').remove('factRef');
      expect(_fact(_project(req), YildiznameFactSubject.moon), isNull);
    });
    test('D non-string factRef → absent', () {
      final req = _req();
      _placement(req, 'moon')['factRef'] = 12;
      expect(_fact(_project(req), YildiznameFactSubject.moon), isNull);
    });
    test('E unrecognized prefix → absent', () {
      final req = _req();
      _placement(req, 'moon')['factRef'] = 'planet.moon';
      expect(_fact(_project(req), YildiznameFactSubject.moon), isNull);
    });
    test('F duplicate body → absent', () {
      final req = _req();
      (req['placements'] as List)
          .add(Map<String, dynamic>.from(_placement(req, 'moon')));
      expect(_fact(_project(req), YildiznameFactSubject.moon), isNull);
    });
  });

  group('angle identity', () {
    test('A both agree → may render', () {
      expect(
        _fact(_project(_req()), YildiznameFactSubject.ascendant),
        isNotNull,
      );
    });
    test('B kind ok / ref missing → absent', () {
      final req = _req();
      _list(req, 'angles')
          .firstWhere((a) => a['kind'] == 'ascendant')
          .remove('factRef');
      expect(_fact(_project(req), YildiznameFactSubject.ascendant), isNull);
    });
    test('C ref ok / kind missing → absent', () {
      final req = _req();
      _list(req, 'angles')
          .firstWhere((a) => a['kind'] == 'ascendant')
          .remove('kind');
      expect(_fact(_project(req), YildiznameFactSubject.ascendant), isNull);
    });
    test('D kind ok / ref unknown → absent', () {
      final req = _req();
      _list(req, 'angles').firstWhere((a) => a['kind'] == 'ascendant')
          ['factRef'] = 'angle.unknown';
      expect(_fact(_project(req), YildiznameFactSubject.ascendant), isNull);
    });
    test('E ref ok / kind unknown → absent', () {
      final req = _req();
      _list(req, 'angles').firstWhere((a) => a['kind'] == 'ascendant')
          ['kind'] = 'rising';
      expect(_fact(_project(req), YildiznameFactSubject.ascendant), isNull);
    });
    test('F Asc kind + MC ref → absent', () {
      final req = _req();
      _list(req, 'angles').firstWhere((a) => a['kind'] == 'ascendant')
          ['factRef'] = 'angle.midheaven';
      expect(_fact(_project(req), YildiznameFactSubject.ascendant), isNull);
    });
    test('G MC kind + Asc ref → absent', () {
      final req = _req();
      _list(req, 'angles').firstWhere((a) => a['kind'] == 'midheaven')
          ['factRef'] = 'angle.ascendant';
      expect(_fact(_project(req), YildiznameFactSubject.midheaven), isNull);
    });
    test('H duplicate angle rows → absent', () {
      final req = _req();
      final asc = Map<String, dynamic>.from(
        _list(req, 'angles').firstWhere((a) => a['kind'] == 'ascendant'),
      );
      (req['angles'] as List).add(asc);
      expect(_fact(_project(req), YildiznameFactSubject.ascendant), isNull);
    });
  });

  group('aspect identity', () {
    test('wrong raw factRef → dropped', () {
      final req = _req();
      _list(req, 'aspects').first['factRef'] = 'aspect.moon.sun.trine';
      expect(_project(req).aspects, isEmpty);
    });
    test('missing factRef → dropped', () {
      final req = _req();
      _list(req, 'aspects').first.remove('factRef');
      expect(_project(req).aspects, isEmpty);
    });
    test('non-string factRef → dropped', () {
      final req = _req();
      _list(req, 'aspects').first['factRef'] = 7;
      expect(_project(req).aspects, isEmpty);
    });
  });
}
