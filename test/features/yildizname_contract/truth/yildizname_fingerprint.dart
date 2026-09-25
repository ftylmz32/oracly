/// Phase 2 — astronomical fingerprint (test-only).
library;

import 'yildizname_candidate_chart.dart';
import 'yildizname_evidence_input.dart';

abstract final class YildiznameAstronomicalFingerprint {
  YildiznameAstronomicalFingerprint._();

  /// Depends only on structured facts / placements / aspects / fidelity.
  /// Ignores locale, narrative, PersonalDiscovery themes.
  static String of(ContractCandidateChart chart) {
    final buf = StringBuffer()
      ..write(chart.evidenceState.name)
      ..write('|')
      ..write(chart.fidelity.name)
      ..write('|')
      ..write(chart.engineCapable)
      ..write('|');
    final facts = [...chart.facts]
      ..sort((a, b) => a.type.name.compareTo(b.type.name));
    for (final f in facts) {
      buf
        ..write(f.type.name)
        ..write(':')
        ..write(f.certainty.name)
        ..write(':')
        ..write(f.fidelity.name)
        ..write(':')
        ..write(f.value)
        ..write(';');
    }
    final placements = [...chart.placements]
      ..sort((a, b) => a.body.compareTo(b.body));
    for (final p in placements) {
      buf
        ..write(p.body)
        ..write('@')
        ..write(p.longitude)
        ..write('/')
        ..write(p.signIndex)
        ..write('/')
        ..write(p.degreeWithinSign)
        ..write(':')
        ..write(p.certainty.name)
        ..write(';');
    }
    final aspects = [...chart.aspects]
      ..sort((a, b) =>
          '${a.bodyA}${a.bodyB}'.compareTo('${b.bodyA}${b.bodyB}'));
    for (final a in aspects) {
      buf
        ..write(a.bodyA)
        ..write('-')
        ..write(a.bodyB)
        ..write(':')
        ..write(a.type)
        ..write('@')
        ..write(a.orb)
        ..write(';');
    }
    if (chart.houseSystem != null) buf.write('hs:${chart.houseSystem}');
    return buf.toString();
  }

  static String evidenceOf(ContractEvidenceInput e) =>
      '${e.hasDate}|${e.hasTime}|${e.hasPlace}|${e.hasTimezone}|${e.timezoneId}';
}
