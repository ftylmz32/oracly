/// Chart behind the 16 Oct 2026 captured reading. Signs and houses are the
/// recorded natal facts; aspect refs come from the reading that cites them.
library;

import 'package:oracly_new/features/star_map/narrative/request/yildizname_angle_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_aspect_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_balance_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_request.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_narrative_scope.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_placement_fact.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

YildiznameNarrativeRequest leoSocialChart(Iterable<String> citedFacts) {
  const rows = <(String, String, int, bool)>[
    ('sun', 'leo', 11, false),
    ('moon', 'leo', 11, false),
    ('mercury', 'leo', 11, true),
    ('venus', 'leo', 11, false),
    ('mars', 'leo', 11, false),
    ('jupiter', 'pisces', 6, true),
    ('saturn', 'taurus', 8, true),
    ('uranus', 'aquarius', 5, true),
    ('neptune', 'aquarius', 5, true),
    ('pluto', 'sagittarius', 3, false),
  ];
  final aspects = <YildiznameAspectFact>[];
  for (final ref in citedFacts.where((r) => r.startsWith('aspect.')).toSet()) {
    final parts = ref.split('.');
    if (parts.length != 4) continue;
    aspects.add(
      YildiznameAspectFact(
        factRef: ref,
        bodyA: parts[1],
        bodyB: parts[2],
        type: parts[3],
        orb: 1,
        certainty: 'exact',
      ),
    );
  }
  return YildiznameNarrativeRequest(
    languageCode: 'tr',
    scope: YildiznameNarrativeScope.full,
    fidelity: 'fullNatalEphemeris',
    houseSystem: 'wholeSign',
    placements: [
      for (final row in rows)
        YildiznamePlacementFact(
          factRef: 'placement.${row.$1}',
          body: row.$1,
          sign: row.$2,
          house: row.$3,
          retrograde: row.$4,
          certainty: 'exact',
        ),
    ],
    angles: const [
      YildiznameAngleFact(
        factRef: 'angle.ascendant',
        kind: 'ascendant',
        sign: 'libra',
        house: 1,
        certainty: 'exact',
      ),
      YildiznameAngleFact(
        factRef: 'angle.midheaven',
        kind: 'midheaven',
        sign: 'cancer',
        house: 10,
        certainty: 'exact',
      ),
    ],
    houses: const [],
    aspects: aspects,
    balances: const [
      YildiznameBalanceFact(
        factRef: 'balance.elements',
        kind: 'elements',
        counts: {'fire': 6, 'earth': 1, 'air': 2, 'water': 1},
        dominant: 'fire',
      ),
      YildiznameBalanceFact(
        factRef: 'balance.modalities',
        kind: 'modalities',
        counts: {'cardinal': 2, 'fixed': 6, 'mutable': 2},
        dominant: 'fixed',
      ),
    ],
    discoveryThemes: const [
      YildiznameThemeFact(themeRef: 'theme.0', label: 'ilişki'),
      YildiznameThemeFact(themeRef: 'theme.1', label: 'dinlenme'),
    ],
    omittedLayers: const [],
  );
}
