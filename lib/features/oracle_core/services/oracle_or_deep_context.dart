/// Premium-only deeper OR observation bits — still never a history dump.
library;

import '../../personal_discovery/services/or_cross_discovery_chambers.dart';
import '../models/oracle_theme_evidence.dart';
import 'oracle_journey_premium_copy.dart';

abstract final class OracleOrDeepContext {
  OracleOrDeepContext._();

  static const maxChars = 360;
  static const minSpanDays = 3;

  static String? compareBit(List<OracleThemeEvidence> evidence) {
    if (evidence.length < 2) return null;
    final sorted = [...evidence]
      ..sort((a, b) => a.observedAt.compareTo(b.observedAt));
    final first = sorted.first;
    final last = sorted.last;
    if (last.observedAt.difference(first.observedAt).inDays < minSpanDays) {
      return null;
    }
    var earlier = OrCrossDiscoveryChambers.label(first.sourceFeature);
    var later = OrCrossDiscoveryChambers.label(last.sourceFeature);
    if (earlier.isEmpty || later.isEmpty) return null;
    if (earlier == later) {
      for (final e in sorted.reversed) {
        final label = OrCrossDiscoveryChambers.label(e.sourceFeature);
        if (label.isNotEmpty && label != earlier) {
          later = label;
          break;
        }
      }
    }
    if (earlier == later) return null;
    return OracleJourneyPremiumCopy.orCompare(
      theme: first.theme,
      earlierArea: earlier,
      laterArea: later,
    );
  }

  static String? areasBit(Set<String> sources, {int max = 5}) {
    final labels = [
      for (final s in sources.take(max)) OrCrossDiscoveryChambers.label(s),
    ].where((l) => l.isNotEmpty).toList();
    if (labels.length < 2) return null;
    // Reuse chamber area phrasing via caller.
    return labels.join(', ');
  }
}
