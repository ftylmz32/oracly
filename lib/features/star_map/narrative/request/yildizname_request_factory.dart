/// NatalChartEvidence → safe YildiznameNarrativeRequest factory.
library;

import '../../../birth_chart/astronomy/natal_chart_evidence.dart';
import 'yildizname_narrative_request.dart';
import 'yildizname_narrative_scope.dart';
import 'yildizname_request_extras.dart';
import 'yildizname_request_fact_builder.dart';

abstract final class YildiznameRequestFactory {
  YildiznameRequestFactory._();

  static YildiznameNarrativeRequest fromEvidence({
    required NatalChartEvidence evidence,
    required String languageCode,
    List<String>? observedRecurringLabels,
  }) {
    final scope =
        YildiznameNarrativeScopeMap.fromFidelity(evidence.fidelity);
    final houseSystem = scope == YildiznameNarrativeScope.full
        ? evidence.houseSystem.name
        : null;
    return YildiznameNarrativeRequest(
      languageCode: languageCode,
      scope: scope,
      fidelity: YildiznameRequestExtras.fidelityName(evidence.fidelity),
      houseSystem: houseSystem,
      calculationVersion: evidence.metadata.calculationVersion,
      placements: YildiznameRequestFactBuilder.placements(evidence, scope),
      angles: YildiznameRequestFactBuilder.angles(evidence, scope),
      houses: YildiznameRequestFactBuilder.houses(evidence, scope),
      aspects: YildiznameRequestFactBuilder.aspects(evidence, scope),
      balances: YildiznameRequestExtras.balances(evidence, scope),
      discoveryThemes: YildiznameRequestExtras.themes(observedRecurringLabels),
      omittedLayers: YildiznameRequestExtras.omittedLayers(evidence, scope),
    );
  }
}
