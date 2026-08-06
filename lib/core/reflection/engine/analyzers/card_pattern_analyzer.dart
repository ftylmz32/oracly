/// RC-010 — Detects frequently appearing cards.
library;

import '../../domain/models/recurring_theme.dart';
import '../../domain/models/reflection_evidence_kind.dart';
import '../../domain/models/reflection_input.dart';
import '../reflection_engine_thresholds.dart';

abstract final class CardPatternAnalyzer {
  CardPatternAnalyzer._();

  static List<RecurringTheme> analyze(ReflectionInput input) {
    final counts = <String, _CardOccurrence>{};

    for (final reading in input.readings) {
      final cards = reading.cards.isEmpty
          ? [(name: reading.cardName, at: reading.createdAt)]
          : [
              for (final card in reading.cards)
                (name: card.cardName, at: reading.createdAt),
            ];

      for (final card in cards) {
        final entry = counts.putIfAbsent(
          card.name,
          () => _CardOccurrence(name: card.name),
        );
        entry.count++;
        entry.dates.add(card.at);
      }
    }

    return counts.values
        .where((entry) => entry.count >= ReflectionEngineThresholds.minCardRecurrence)
        .map((entry) {
          entry.dates.sort();
          return RecurringTheme(
            id: 'card:${entry.name.toLowerCase()}',
            label: entry.name,
            occurrenceCount: entry.count,
            firstObserved: entry.dates.first,
            lastObserved: entry.dates.last,
            evidence: ReflectionEvidenceKind.cardDraw,
          );
        })
        .toList();
  }
}

class _CardOccurrence {
  _CardOccurrence({required this.name});

  final String name;
  int count = 0;
  final List<DateTime> dates = [];
}
