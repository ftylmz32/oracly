/// Phase 8B — orchestrator success paths (E2/E4, semantic identity).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_presentation.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_source.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_execution.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';

import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);

  test('D E2 → narrative reduced ready', () async {
    final storage = phase8bStorage();
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE2());
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ready);
    expect(exec.artifact!.source, YildiznameArtifactSource.narrativeV1);
    expect(exec.artifact!.scope, 'reduced');
    expect(exec.presentation!.source, YildiznameResultSource.narrativeLive);
    expect(exec.presentation!.isHistoricalArtifact, isFalse);
    expect(exec.presentation!.historicalStatus, isNull);
    expect(exec.presentation!.actions.hasFavorite, isTrue);
  });

  test('E E4 → narrative full ready', () async {
    final storage = phase8bStorage();
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE4());
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ready);
    expect(exec.artifact!.scope, 'full');
    expect(exec.presentation!.factSnapshot.isEmpty, isFalse);
  });

  test('Q/R semanticFingerprint == requestFingerprint; evidence separate',
      () async {
    final storage = phase8bStorage();
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE2());
    final plan = await orch.preflight(languageCode: 'en');
    expect(plan.request, isNotNull);
    final exec = await orch.execute(languageCode: 'en');
    final a = exec.artifact!;
    expect(
      a.semanticFingerprint,
      YildiznameRequestFingerprint.of(plan.request!),
    );
    expect(a.evidenceFingerprint, plan.evidenceFingerprint);
    expect(a.semanticFingerprint, isNot(equals(a.evidenceFingerprint)));
  });

  test('O/P reopen is historical; live is not', () async {
    final storage = phase8bStorage();
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE2());
    final exec = await orch.execute(languageCode: 'en');
    final live = exec.presentation!;
    final reopen = YildiznameArtifactPresentation.of(exec.artifact!);
    expect(live.source, YildiznameResultSource.narrativeLive);
    expect(live.historicalStatus, isNull);
    expect(reopen.source, YildiznameResultSource.narrativeArtifact);
    expect(reopen.isHistoricalArtifact, isTrue);
    expect(reopen.historicalStatus, isNotNull);
    expect(reopen.sections.map((s) => s.body), live.sections.map((s) => s.body));
  });

  test('B/C flag true + E1/E3 → legacyLocal, provider 0', () async {
    for (final chart in [phase8bE1(), phase8bE3()]) {
      final orch = phase8bOrchestrator(
        storage: phase8bStorage(),
        chart: chart,
      );
      final exec = await orch.execute(languageCode: 'tr');
      expect(exec.kind, YildiznameLiveExecutionKind.legacyLocal);
      expect(exec.providerCallCount, 0);
    }
  });

  test('A flag false + E4 → legacyLocal', () async {
    final orch = phase8bOrchestrator(
      storage: phase8bStorage(),
      chart: phase8bE4(),
      flag: false,
    );
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.legacyLocal);
    expect(exec.providerCallCount, 0);
  });
}
