/// Phase 7B — fail-closed scope resolution from STORED evidence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';
import 'package:oracly_new/features/star_map/result/yildizname_scope_resolver.dart';

import '../../../support/yildizname_result_fixtures.dart';

YildiznameResolvedScope _resolve({
  String? artifactScope,
  String? artifactFidelity,
  Map<String, dynamic>? request,
  Map<String, dynamic>? result,
}) => YildiznameScopeResolver.resolveNarrative(
  artifactScope: artifactScope,
  artifactFidelity: artifactFidelity,
  request: request,
  result: result,
);

Map<String, dynamic> _req(
  YildiznameNarrativeScope scope, {
  bool ascendant = true,
  bool midheaven = true,
  bool houses = true,
  bool aspects = true,
}) => yildiznameFixtureRequest(
  scope: scope,
  ascendant: ascendant,
  midheaven: midheaven,
  houses: houses,
  aspects: aspects,
).toProviderJson();

void main() {
  group('consistent evidence resolves to its own scope', () {
    test('legacy', () {
      final r = _resolve(
        artifactScope: 'legacy',
        artifactFidelity: 'tropicalSunSign',
        request: _req(YildiznameNarrativeScope.legacy),
        result: {'scope': 'legacy'},
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('reduced — no optional layers claimed', () {
      final r = _resolve(
        artifactScope: 'reduced',
        artifactFidelity: 'reducedNatal',
        request: _req(YildiznameNarrativeScope.reduced),
        result: {'scope': 'reduced'},
      );
      expect(r.scope, YildiznameResultScope.reduced);
      expect(r.hasAscendant, isFalse);
      expect(r.hasMidheaven, isFalse);
      expect(r.hasHouses, isFalse);
      expect(r.hasAspects, isFalse);
    });

    test('full with every layer present', () {
      final r = _resolve(
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
        request: _req(YildiznameNarrativeScope.full),
        result: {'scope': 'full'},
      );
      expect(r.scope, YildiznameResultScope.full);
      expect(r.hasAscendant, isTrue);
      expect(r.hasMidheaven, isTrue);
      expect(r.hasHouses, isTrue);
      expect(r.hasAspects, isTrue);
      expect(r.fullLayersComplete, isTrue);
    });
  });

  group('FULL never means every layer is present', () {
    YildiznameResolvedScope full(Map<String, dynamic> request) => _resolve(
      artifactScope: 'full',
      artifactFidelity: 'fullNatalEphemeris',
      request: request,
      result: {'scope': 'full'},
    );

    test('FULL + omitted houses does not claim houses', () {
      final r = full(_req(YildiznameNarrativeScope.full, houses: false));
      expect(r.scope, YildiznameResultScope.full);
      expect(r.hasHouses, isFalse);
      expect(r.hasAscendant, isTrue);
      expect(r.fullLayersComplete, isFalse);
    });

    test('FULL + omitted ascendant does not claim Ascendant', () {
      final r = full(_req(YildiznameNarrativeScope.full, ascendant: false));
      expect(r.scope, YildiznameResultScope.full);
      expect(r.hasAscendant, isFalse);
      expect(r.fullLayersComplete, isFalse);
    });

    test('FULL + omitted midheaven / aspects are not claimed either', () {
      final r = full(
        _req(YildiznameNarrativeScope.full, midheaven: false, aspects: false),
      );
      expect(r.hasMidheaven, isFalse);
      expect(r.hasAspects, isFalse);
      expect(r.fullLayersComplete, isFalse);
    });

    test('a layer both present AND listed omitted is not claimed', () {
      final request = _req(YildiznameNarrativeScope.full);
      (request['omittedLayers'] as List).add('ascendant');
      final r = full(request);
      expect(r.hasAscendant, isFalse);
      expect(r.hasMidheaven, isTrue);
    });
  });

  group('conflicting / incomplete metadata never upgrades the claim', () {
    test('artifact full but request.scope reduced → reduced', () {
      final r = _resolve(
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
        request: _req(YildiznameNarrativeScope.reduced),
        result: {'scope': 'reduced'},
      );
      expect(r.scope, YildiznameResultScope.reduced);
    });

    test('scope full but fidelity reducedNatal → reduced', () {
      final r = _resolve(
        artifactScope: 'full',
        artifactFidelity: 'reducedNatal',
        request: _req(YildiznameNarrativeScope.full),
      );
      expect(r.scope, YildiznameResultScope.reduced);
      expect(r.hasHouses, isFalse, reason: 'no layer claims below FULL');
    });

    test('scope full but result.scope legacy → legacy', () {
      final r = _resolve(
        artifactScope: 'full',
        request: _req(YildiznameNarrativeScope.full),
        result: {'scope': 'legacy'},
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('markers say full but the stored structure is only reduced', () {
      final r = _resolve(
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
        request: {
          ..._req(YildiznameNarrativeScope.reduced),
          'scope': 'full',
          'fidelity': 'fullNatalEphemeris',
        },
        result: {'scope': 'full'},
      );
      expect(r.scope, YildiznameResultScope.reduced);
    });

    test('markers say full but omittedLayers lists exactDegrees → reduced', () {
      final request = _req(YildiznameNarrativeScope.full);
      (request['omittedLayers'] as List).add('exactDegrees');
      final r = _resolve(
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
        request: request,
        result: {'scope': 'full'},
      );
      expect(r.scope, YildiznameResultScope.reduced);
    });

    test(
      'markers say full but omittedLayers lists personal planets → legacy',
      () {
        final request = _req(YildiznameNarrativeScope.full);
        (request['omittedLayers'] as List).add('personalPlanets');
        final r = _resolve(
          artifactScope: 'full',
          artifactFidelity: 'fullNatalEphemeris',
          request: request,
        );
        expect(r.scope, YildiznameResultScope.legacy);
      },
    );

    test('rich stored structure cannot outrank a legacy claim', () {
      final r = _resolve(
        artifactScope: 'legacy',
        artifactFidelity: 'tropicalSunSign',
        request: {
          ..._req(YildiznameNarrativeScope.full),
          'scope': 'legacy',
          'fidelity': 'tropicalSunSign',
        },
      );
      expect(r.scope, YildiznameResultScope.legacy);
      expect(r.hasAscendant, isFalse);
    });

    test('unrecognized scope string supports no claim', () {
      final r = _resolve(
        artifactScope: 'ultra',
        artifactFidelity: 'fullNatalEphemeris',
        request: _req(YildiznameNarrativeScope.full),
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('non-string marker supports no claim', () {
      final request = _req(YildiznameNarrativeScope.full)..['scope'] = 2;
      final r = _resolve(artifactScope: 'full', request: request);
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('no markers at all cannot prove any richer scope', () {
      final r = _resolve(
        request: {
          ..._req(YildiznameNarrativeScope.full)
            ..remove('scope')
            ..remove('fidelity'),
        },
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('artifact claims full but the request is missing → legacy', () {
      final r = _resolve(
        artifactScope: 'full',
        artifactFidelity: 'fullNatalEphemeris',
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('reduced claim with a bare Sun and no balances is unprovable', () {
      final r = _resolve(
        artifactScope: 'reduced',
        artifactFidelity: 'reducedNatal',
        request: {
          'scope': 'reduced',
          'fidelity': 'reducedNatal',
          'placements': [
            {'factRef': 'place.sun.leo', 'body': 'sun', 'sign': 'leo'},
          ],
          'omittedLayers': ['angles', 'houses'],
        },
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });

    test('blank markers are absent, not conflicting', () {
      final r = _resolve(
        artifactScope: '  ',
        artifactFidelity: '',
        request: _req(YildiznameNarrativeScope.reduced),
      );
      expect(r.scope, YildiznameResultScope.reduced);
    });

    test('malformed request arrays never throw', () {
      final r = _resolve(
        artifactScope: 'full',
        request: {
          'scope': 'full',
          'placements': 'nope',
          'angles': 5,
          'houses': {'a': 1},
          'omittedLayers': 'ascendant',
          'houseSystem': 3,
        },
      );
      expect(r.scope, YildiznameResultScope.legacy);
    });
  });

  test('resolution is deterministic', () {
    YildiznameResolvedScope run() => _resolve(
      artifactScope: 'full',
      artifactFidelity: 'fullNatalEphemeris',
      request: _req(YildiznameNarrativeScope.full, houses: false),
      result: {'scope': 'full'},
    );
    expect(run(), run());
    expect(run().hashCode, run().hashCode);
  });
}
