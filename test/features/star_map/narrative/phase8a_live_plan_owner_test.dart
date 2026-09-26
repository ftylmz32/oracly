/// Phase 8A — owner preconditions + cross-owner history firewall.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';

import 'phase8a_live_plan_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('H valid reduced + null owner → ownerUnavailable', () {
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: null,
      chart: phase8aChart(phase8aE2Profile()),
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.ownerUnavailable);
    expect(plan.request, isNull);
  });

  test('I valid full + blank/whitespace owner → ownerUnavailable', () {
    for (final owner in ['', '   ', '\t']) {
      final plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: owner,
        chart: phase8aChart(phase8aE4Profile()),
        languageCode: 'tr',
      );
      expect(plan.kind, YildiznameLivePlanKind.ownerUnavailable, reason: owner);
    }
  });

  test('P other-owner history excluded from themes', () {
    final chart = phase8aChart(phase8aE2Profile());
    final foreign = [
      phase8aNarrativeArtifact(
        ownerId: 'owner-b',
        id: 'yid_cccccccccccccccccccccccccccccccc',
        label: 'YabancıTema',
        at: DateTime.utc(2026, 1, 1),
        semantic: 'fb1',
      ),
      phase8aNarrativeArtifact(
        ownerId: 'owner-b',
        id: 'yid_dddddddddddddddddddddddddddddddd',
        label: 'YabancıTema',
        at: DateTime.utc(2026, 2, 1),
        semantic: 'fb2',
      ),
    ];
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: chart,
      languageCode: 'tr',
      artifactHistory: foreign,
    );
    expect(plan.kind, YildiznameLivePlanKind.narrativeReduced);
    final labels = plan.request!.discoveryThemes.map((t) => t.label);
    expect(labels, isNot(contains('YabancıTema')));
  });

  test('flag false + missing owner still legacyLocal (not ownerUnavailable)', () {
    final plan = YildiznameLivePlanBuilder.build(
      featureEnabled: false,
      ownerId: null,
      chart: phase8aChart(phase8aE4Profile()),
      languageCode: 'tr',
    );
    expect(plan.kind, YildiznameLivePlanKind.legacyLocal);
  });
}
