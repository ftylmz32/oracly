/// Phase 8B — semantic fingerprint freeze vs facts-only / evidence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_execution.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_plan_builder.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';

import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('Q semanticFingerprint == YildiznameRequestFingerprint.of(request)',
      () async {
    final orch = phase8bOrchestrator(
      storage: phase8bStorage(),
      chart: phase8bE2(),
    );
    final plan = await orch.preflight(languageCode: 'en');
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ready);
    expect(
      exec.artifact!.semanticFingerprint,
      YildiznameRequestFingerprint.of(plan.request!),
    );
    expect(exec.artifact!.semanticFingerprint, plan.requestFingerprint);
    expect(exec.artifact!.evidenceFingerprint, plan.evidenceFingerprint);
  });

  test('R theme labels change semantic; facts-only stays', () {
    final bare = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: phase8bE2(),
      languageCode: 'en',
      artifactHistory: const [],
      personalDiscoveryLabels: const [],
    );
    final withThemes = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: 'owner-a',
      chart: phase8bE2(),
      languageCode: 'en',
      artifactHistory: const [],
      personalDiscoveryLabels: const ['Sabır', 'Odak'],
    );
    expect(bare.isNarrativeEligible, isTrue);
    expect(withThemes.isNarrativeEligible, isTrue);
    expect(bare.factsOnlyFingerprint, withThemes.factsOnlyFingerprint);
    expect(bare.requestFingerprint, isNot(equals(withThemes.requestFingerprint)));
    expect(
      bare.evidenceFingerprint,
      withThemes.evidenceFingerprint,
    );
    expect(
      withThemes.requestFingerprint,
      YildiznameRequestFingerprint.of(withThemes.request!),
    );
    expect(
      withThemes.factsOnlyFingerprint,
      YildiznameRequestFingerprint.factsOnly(withThemes.request!),
    );
  });
}
