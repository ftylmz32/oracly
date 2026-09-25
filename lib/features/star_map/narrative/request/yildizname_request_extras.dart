/// Balances, themes, omitted layers for Narrative request factory.
library;

import '../../../birth_chart/astronomy/astronomical_fact_certainty.dart';
import '../../../birth_chart/astronomy/natal_chart_evidence.dart';
import '../../../birth_chart/models/chart_fidelity.dart';
import '../versions.dart';
import 'yildizname_balance_fact.dart';
import 'yildizname_narrative_scope.dart';
import 'yildizname_theme_fact.dart';

abstract final class YildiznameRequestExtras {
  YildiznameRequestExtras._();

  static List<YildiznameBalanceFact> balances(
    NatalChartEvidence evidence,
    YildiznameNarrativeScope scope,
  ) {
    if (scope == YildiznameNarrativeScope.legacy) return const [];
    final el = evidence.elementBalance;
    final mod = evidence.modalityBalance;
    return [
      YildiznameBalanceFact(
        factRef: 'balance.elements',
        kind: 'elements',
        counts: {
          'fire': el.fire,
          'earth': el.earth,
          'air': el.air,
          'water': el.water,
        },
        dominant: el.dominant.name,
      ),
      YildiznameBalanceFact(
        factRef: 'balance.modalities',
        kind: 'modalities',
        counts: {
          for (final e in mod.entries) e.key.name: e.value,
        },
        dominant: _dominantModality(mod),
      ),
    ];
  }

  static String? _dominantModality(Map<dynamic, int> mod) {
    if (mod.isEmpty) return null;
    var bestName = '';
    var best = -1;
    for (final e in mod.entries) {
      if (e.value > best) {
        best = e.value;
        bestName = e.key is Enum ? (e.key as Enum).name : '$e.key';
      }
    }
    return bestName.isEmpty ? null : bestName;
  }

  static List<YildiznameThemeFact> themes(List<String>? labels) {
    if (labels == null || labels.isEmpty) return const [];
    final trimmed = <String>[];
    for (final raw in labels) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      if (t.length > kYildiznameMaxThemeLabelChars) continue;
      trimmed.add(t);
      if (trimmed.length >= kYildiznameMaxThemes) break;
    }
    return [
      for (var i = 0; i < trimmed.length; i++)
        YildiznameThemeFact(themeRef: 'theme.$i', label: trimmed[i]),
    ];
  }

  static List<String> omittedLayers(
    NatalChartEvidence evidence,
    YildiznameNarrativeScope scope,
  ) {
    final out = <String>[];
    if (scope == YildiznameNarrativeScope.legacy) {
      out.addAll(const [
        'moon',
        'exactDegrees',
        'ascendant',
        'midheaven',
        'houses',
        'aspects',
        'personalPlanets',
      ]);
      return out;
    }
    if (scope == YildiznameNarrativeScope.reduced) {
      out.addAll(const [
        'exactDegrees',
        'ascendant',
        'midheaven',
        'houses',
        'aspects',
        'retrograde',
      ]);
      for (final p in evidence.placements) {
        if (p.certainty == AstronomicalFactCertainty.ambiguous ||
            p.certainty == AstronomicalFactCertainty.unavailable) {
          out.add('ambiguous.${p.body.name}');
        }
      }
      return out;
    }
    if (evidence.ascendant == null) out.add('ascendant');
    if (evidence.midheaven == null) out.add('midheaven');
    if (evidence.houses.isEmpty) out.add('houses');
    if (evidence.aspects.isEmpty) out.add('aspects');
    return out;
  }

  static String fidelityName(ChartCalculationFidelity f) => f.name;
}
