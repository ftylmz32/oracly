/// Phase 8C.2d — synthetic FULL request for aspect / house / angle grounding.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_angle_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_aspect_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_error.dart';

YildiznamePlacementFact _p(String body, String sign, int house) =>
    YildiznamePlacementFact(
      factRef: 'placement.$body',
      body: body,
      sign: sign,
      certainty: 'exact',
      house: house,
    );

YildiznameAspectFact aspectFact(String a, String b, String type) =>
    YildiznameAspectFact(
      factRef: 'aspect.$a.$b.$type',
      bodyA: a,
      bodyB: b,
      type: type,
      orb: 2,
      certainty: 'exact',
    );

/// Sun Leo (10), Moon Taurus (7), Venus Libra (11), Mars Aries (5);
/// Ascendant Libra, Midheaven Aquarius. Only [aspects] are known.
YildiznameNarrativeRequest phase8c2dRequest({
  List<YildiznameAspectFact> aspects = const [],
  String languageCode = 'tr',
}) =>
    YildiznameNarrativeRequest(
      languageCode: languageCode,
      scope: YildiznameNarrativeScope.full,
      fidelity: 'fullNatalEphemeris',
      houseSystem: 'wholeSign',
      calculationVersion: 'calc-fixture',
      placements: [
        _p('sun', 'leo', 10),
        _p('moon', 'taurus', 7),
        _p('venus', 'libra', 11),
        _p('mars', 'aries', 5),
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
      aspects: aspects,
      balances: const [],
      discoveryThemes: const [],
      omittedLayers: const [],
    );

Matcher groundingError(String message) => throwsA(
      isA<YildiznameResultException>()
          .having((e) => e.kind, 'kind', YildiznameResultErrorKind.grounding)
          .having((e) => e.message, 'message', message),
    );
