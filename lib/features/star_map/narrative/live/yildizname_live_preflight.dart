/// Phase 8B — local preflight planning (chart + eligibility, no provider).
library;

import '../../../birth_chart/models/birth_chart.dart';
import '../../artifacts/yildizname_artifact.dart';
import 'yildizname_live_orchestrator_deps.dart';
import 'yildizname_live_owner_snapshot.dart';
import 'yildizname_live_plan.dart';
import 'yildizname_live_plan_builder.dart';

final class YildiznameLivePreflight {
  YildiznameLivePreflight(this._deps);

  final YildiznameLiveOrchestratorDeps _deps;

  Future<({YildiznameLivePlan plan, BirthChart? chart})> plan({
    required YildiznameLiveOwnerSnapshot expected,
    required String languageCode,
    bool allowEvidenceRepair = true,
  }) async {
    if (!_deps.flagEnabled()) {
      return (plan: YildiznameLivePlan.legacyLocal(), chart: null);
    }
    if (!expected.isValid) {
      return (plan: YildiznameLivePlan.ownerUnavailable(), chart: null);
    }
    if (!expected.matches(_deps.storage)) {
      return (plan: YildiznameLivePlan.ownerUnavailable(), chart: null);
    }

    BirthChart? chart;
    try {
      chart = await _deps.loadChart();
    } catch (_) {
      chart = null;
    }

    final history = await _safeHistory();
    final labels = await _safeDiscoveryLabels();
    final name = await _safeAddressName();
    // The name store is account-scoped; re-check before it shapes a request.
    if (!expected.matches(_deps.storage)) {
      return (plan: YildiznameLivePlan.ownerUnavailable(), chart: null);
    }
    var plan = YildiznameLivePlanBuilder.build(
      featureEnabled: true,
      ownerId: expected.ownerId,
      chart: chart,
      languageCode: languageCode,
      artifactHistory: history,
      personalDiscoveryLabels: labels,
      addressName: name,
    );

    if (plan.kind == YildiznameLivePlanKind.invalidEvidence &&
        allowEvidenceRepair &&
        chart != null) {
      chart = await _tryRepair(chart);
      if (!expected.matches(_deps.storage)) {
        return (plan: YildiznameLivePlan.ownerUnavailable(), chart: null);
      }
      plan = YildiznameLivePlanBuilder.build(
        featureEnabled: true,
        ownerId: expected.ownerId,
        chart: chart,
        languageCode: languageCode,
        artifactHistory: history,
        personalDiscoveryLabels: labels,
        addressName: name,
      );
    }
    return (plan: plan, chart: chart);
  }

  Future<BirthChart?> _tryRepair(BirthChart chart) async {
    try {
      return await _deps.repairChart(chart);
    } catch (_) {
      return chart;
    }
  }

  Future<List<YildiznameArtifact>> _safeHistory() async {
    try {
      return await _deps.artifacts.getAll();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _safeAddressName() async {
    final loader = _deps.addressName;
    if (loader == null) return null;
    try {
      return await loader();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _safeDiscoveryLabels() async {
    final loader = _deps.personalDiscoveryLabels;
    if (loader == null) return const [];
    try {
      return await loader();
    } catch (_) {
      return const [];
    }
  }
}
