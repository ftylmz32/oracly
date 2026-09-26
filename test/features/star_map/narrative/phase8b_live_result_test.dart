/// Phase 8B — live presentation actions + continuity + historical absence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/features/birth_chart/astronomy/birth_timezone_database.dart';
import 'package:oracly_new/features/star_map/artifacts/local_yildizname_artifact_repository.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_id.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_narrative_completion_service.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator.dart';
import 'package:oracly_new/features/star_map/narrative/live/yildizname_live_orchestrator_deps.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';
import 'package:oracly_new/features/star_map/narrative/result/yildizname_result_parser.dart';
import 'package:oracly_new/features/star_map/result/yildizname_result_types.dart';

import '../artifacts/phase6_test_support.dart';
import 'phase8b_approved_payload.dart';
import 'phase8b_test_support.dart';

void main() {
  setUpAll(BirthTimezoneDatabase.ensureInitialized);
  tearDown(() {
    YildiznameArtifactId.generator = YildiznameArtifactId.secure;
  });

  test('T54 live actions: OR Share Favorite Copy Continuation', () async {
    final storage = phase8bStorage();
    final orch = phase8bOrchestrator(storage: storage, chart: phase8bE2());
    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ready);
    final a = exec.presentation!.actions;
    expect(a.hasOr, isTrue);
    expect(a.hasFavorite, isTrue);
    expect(a.share.highlight.isNotEmpty, isTrue);
    expect(a.copyText.isNotEmpty, isTrue);
    expect(a.continuationThemes, isNotEmpty);
    expect(a.favorite!.artifactId, exec.artifact!.id);
    expect(a.favorite!.occurredAt, exec.artifact!.createdAtUtc);
    expect(exec.presentation!.source, YildiznameResultSource.narrativeLive);
    expect(exec.presentation!.historicalStatus, isNull);
  });

  test('T55 continuity appears when prior recurrence intersects', () async {
    useFixedIds(const [
      'yid_8b01aaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'yid_8b02bbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'yid_8b03cccccccccccccccccccccccccccc',
    ]);
    final storage = phase8bStorage();
    final owner = storage.getString(UserLocalDataIsolation.ownerKey)!;
    final repo = LocalYildiznameArtifactRepository(storage, ownerId: owner);
    final completion = YildiznameNarrativeCompletionService(repo);
    await completion.complete(
      ownerId: owner,
      request: sampleRequest(
        themes: const [YildiznameThemeFact(themeRef: 'theme.0', label: 'Sabır')],
      ),
      result: sampleResult(themeRefs: const ['theme.0']),
      semanticFingerprint: 'prior-a',
      createdAtUtc: DateTime.utc(2026, 1, 1),
    );
    await completion.complete(
      ownerId: owner,
      request: sampleRequest(
        themes: const [YildiznameThemeFact(themeRef: 'theme.1', label: 'Sabır')],
      ),
      result: sampleResult(themeRefs: const ['theme.1']),
      semanticFingerprint: 'prior-b',
      createdAtUtc: DateTime.utc(2026, 1, 2),
    );

    final orch = YildiznameLiveOrchestrator(
      YildiznameLiveOrchestratorDeps(
        storage: storage,
        loadChart: () async => phase8bE2(),
        repairChart: (c) async => c,
        artifacts: repo,
        completion: completion,
        flagEnabled: () => true,
        nowUtc: () => DateTime.utc(2026, 9, 26, 12),
        personalDiscoveryLabels: () async => const ['Sabır'],
        generateOverride: ({required request, forceRefresh = false}) async {
          final payload = phase8bApprovedPayload(request);
          final refs = [
            for (final t in request.discoveryThemes) t.themeRef,
          ];
          final summary = Map<String, dynamic>.from(payload['summary'] as Map);
          summary['themeRefs'] = refs;
          payload['summary'] = summary;
          final sections = <Map<String, dynamic>>[
            for (final s in payload['sections'] as List)
              () {
                final m = Map<String, dynamic>.from(s as Map);
                m['themeRefs'] = refs;
                return m;
              }(),
          ];
          payload['sections'] = sections;
          return YildiznameResultParser.parse(payload);
        },
        readProviderCallCount: () => 1,
      ),
    );

    final exec = await orch.execute(languageCode: 'en');
    expect(exec.kind, YildiznameLiveExecutionKind.ready);
    expect(exec.presentation!.continuity.isEmpty, isFalse);
    expect(exec.presentation!.continuity.labels, contains('Sabır'));
    final joined =
        '${exec.presentation!.continuity.heading} ${exec.presentation!.continuity.body}';
    expect(joined.contains('theme.'), isFalse);
    expect(joined.contains(owner), isFalse);
  });
}
