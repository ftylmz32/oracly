/// Phase 8B — Riverpod wiring for live Narrative orchestration.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/feature_flags/feature_flag_runtime.dart';
import '../../../../core/feature_flags/product_feature_flags.dart';
import '../../../../core/providers/backend_providers.dart';
import '../../../ai/production/oracly_ai_providers.dart';
import '../../../ai/production/oracly_narrative_yildizname_ai_service.dart';
import '../../../birth_chart/providers/birth_chart_providers.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../artifacts/yildizname_artifact_providers.dart';
import 'yildizname_live_orchestrator.dart';
import 'yildizname_live_orchestrator_deps.dart';
import 'yildizname_narrative_live_gate.dart';

final yildiznameLiveOrchestratorProvider =
    Provider<YildiznameLiveOrchestrator>((ref) {
  ref.watch(localDataOwnerEpochProvider);
  final ai = ref.watch(oraclyAiServiceProvider);
  final OraclyNarrativeYildiznameAiService? narrativeAi =
      ai is OraclyNarrativeYildiznameAiService
          ? ai as OraclyNarrativeYildiznameAiService
          : null;
  final charts = ref.watch(birthChartExperienceServiceProvider);
  return YildiznameLiveOrchestrator(
    YildiznameLiveOrchestratorDeps(
      storage: ref.watch(localStorageProvider),
      loadChart: () => charts.loadSavedChart(),
      repairChart: (chart) => charts.ensureChartReady(chart),
      artifacts: ref.watch(yildiznameArtifactRepositoryProvider),
      completion: ref.watch(yildiznameNarrativeCompletionServiceProvider),
      flagEnabled: () => YildiznameNarrativeLiveGate.isEnabled,
      nowUtc: () => DateTime.now().toUtc(),
      narrativeAi: narrativeAi,
      personalDiscoveryLabels: () async {
        try {
          final profile =
              await ref.read(personalDiscoveryProfileProvider.future);
          return profile.observedRecurringLabels;
        } catch (_) {
          return const <String>[];
        }
      },
      onArtifactPersisted: yildiznameArtifactPersistedHook(ref),
    ),
  );
});

/// Canonical artifact-history refresh after a verified durable save.
/// Goes through the container so a rebuilt orchestrator `ref` cannot block it.
YildiznameArtifactPersisted yildiznameArtifactPersistedHook(Ref ref) {
  final container = ref.container;
  return () => container.invalidate(yildiznameArtifactHistoryProvider);
}

/// Test helper — force remote-style flag value without changing defaults map.
void yildiznameNarrativeFlagOverride(bool enabled) {
  FeatureFlagRuntime.refreshFromRemote({
    ProductFeatureFlags.yildiznameNarrativeV1.key: enabled,
  });
}

/// Reset flags to product defaults (tests).
void yildiznameNarrativeFlagReset() {
  FeatureFlagRuntime.refreshFromRemote(const {});
}

/// Owner key constant re-export for tests.
const kYildiznameOwnerStorageKey = UserLocalDataIsolation.ownerKey;
