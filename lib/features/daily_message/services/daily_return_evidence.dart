/// Localized evidence lines from a real insight note — never invented memory.
library;

import '../../../core/l10n/l10n.dart';

abstract final class DailyReturnEvidence {
  DailyReturnEvidence._();

  static List<String> lines({
    required DateTime day,
    required String theme,
    required String? explanation,
    required bool hasDiscoveries,
  }) {
    if (!hasDiscoveries) return const [];
    final note = explanation?.trim();
    if (note == null || note.isEmpty) return const [];
    String line(String key) => OraclyL10n.t(key)
        .replaceAll('{note}', note)
        .replaceAll('{theme}', theme);
    final sharp = line('daily.evidence.sharp');
    final directed = line('daily.evidence.directed');
    final next = line('daily.evidence.next');
    final pause = line('daily.evidence.pause');
    final mode = (day.day + day.month * 3) % 4;
    return switch (mode) {
      0 => [sharp, directed, next, pause],
      1 => [directed, pause, sharp, next],
      2 => [next, sharp, pause, directed],
      _ => [pause, next, directed, sharp],
    };
  }
}
