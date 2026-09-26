/// Phase 8B — explicit orchestrator dependencies (testable, no BuildContext).
library;

import '../../../../core/data/datasources/local_storage.dart';
import '../../../ai/production/oracly_narrative_yildizname_ai_service.dart';
import '../../../birth_chart/models/birth_chart.dart';
import '../../artifacts/yildizname_artifact_repository.dart';
import '../../artifacts/yildizname_narrative_completion_service.dart';
import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import 'yildizname_narrative_live_service.dart';

typedef YildiznameUtcClock = DateTime Function();
typedef YildiznameFlagReader = bool Function();
typedef YildiznamePersonalDiscoveryLabels = Future<List<String>> Function();
typedef YildiznameChartLoader = Future<BirthChart?> Function();
typedef YildiznameChartRepair = Future<BirthChart> Function(BirthChart chart);
typedef YildiznameNarrativeGenerate = Future<YildiznameNarrativeStructuredResult>
    Function({
  required YildiznameNarrativeRequest request,
  bool forceRefresh,
});

final class YildiznameLiveOrchestratorDeps {
  YildiznameLiveOrchestratorDeps({
    required this.storage,
    required this.loadChart,
    required this.repairChart,
    required this.artifacts,
    required this.completion,
    required this.flagEnabled,
    required this.nowUtc,
    this.narrativeAi,
    this.liveService,
    this.generateOverride,
    this.personalDiscoveryLabels,
    this.readProviderCallCount = _zero,
  });

  final LocalStorage storage;
  final YildiznameChartLoader loadChart;
  final YildiznameChartRepair repairChart;
  final YildiznameArtifactRepository artifacts;
  final YildiznameNarrativeCompletionService completion;
  final YildiznameFlagReader flagEnabled;
  final YildiznameUtcClock nowUtc;
  final OraclyNarrativeYildiznameAiService? narrativeAi;
  final YildiznameNarrativeLiveService? liveService;
  final YildiznameNarrativeGenerate? generateOverride;
  final YildiznamePersonalDiscoveryLabels? personalDiscoveryLabels;
  final int Function() readProviderCallCount;

  static int _zero() => 0;

  YildiznameNarrativeGenerate? resolveGenerate() {
    if (generateOverride != null) return generateOverride;
    final live = liveService ??
        (narrativeAi != null
            ? YildiznameNarrativeLiveService(
                ai: narrativeAi!,
                enforceFlag: false,
              )
            : null);
    if (live == null) return null;
    return ({required request, forceRefresh = false}) =>
        live.generate(request: request, forceRefresh: forceRefresh);
  }
}
