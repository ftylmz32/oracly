/// Detect genuine patterns across stored dreams — never quote raw text.
library;

import '../../../core/l10n/oracly_format.dart';
import '../models/dream.dart';
import '../models/dream_insight.dart';
import 'dream_analysis_beats.dart';
import 'dream_analysis_facts.dart';

class DreamPatternMatch {
  const DreamPatternMatch({
    required this.sharedSymbols,
    required this.sharedTags,
    required this.previousDreamId,
    required this.previousDreamDate,
  });

  final List<String> sharedSymbols;
  final List<String> sharedTags;
  final String previousDreamId;
  final DateTime previousDreamDate;
}

class DreamPatternService {
  const DreamPatternService();

  static String formatDate(DateTime date) => OraclyFormat.dateNumeric(date);

  /// Returns null when no genuine overlap exists.
  DreamPatternMatch? findConnection({
    required Dream current,
    required List<Dream> previousDreams,
  }) {
    if (previousDreams.isEmpty || current.understanding == null) return null;

    final currentSymbols = current.understanding!.symbols
        .map((s) => s.label.toLowerCase())
        .toSet();
    final currentTags = current.tags.map((t) => t.toLowerCase()).toSet();

    DreamPatternMatch? best;
    var bestScore = 0;

    for (final prior in previousDreams) {
      if (prior.id == current.id) continue;
      if (prior.understanding == null) continue;

      final priorSymbols = prior.understanding!.symbols
          .map((s) => s.label.toLowerCase())
          .toSet();
      final priorTags = prior.tags.map((t) => t.toLowerCase()).toSet();

      final sharedSymbols =
          currentSymbols.intersection(priorSymbols).toList()..sort();
      final sharedTags = currentTags.intersection(priorTags).toList()..sort();

      final score = sharedSymbols.length * 2 + sharedTags.length;
      final hasGenuinePattern =
          sharedSymbols.length >= 2 ||
          (sharedSymbols.isNotEmpty && sharedTags.isNotEmpty);

      if (hasGenuinePattern && score > bestScore) {
        bestScore = score;
        best = DreamPatternMatch(
          sharedSymbols: sharedSymbols.map(_titleCase).toList(),
          sharedTags: sharedTags,
          previousDreamId: prior.id,
          previousDreamDate: prior.recordedAt,
        );
      }
    }

    return best;
  }

  DreamInsight? buildConnectionInsight(DreamPatternMatch? match) {
    if (match == null) return null;
    final facts = DreamAnalysisFacts.from(
      narrative: '',
      understanding: const DreamUnderstanding(
        symbols: [],
        emotions: [],
        locations: [],
        relationships: [],
        recurringElements: [],
        summary: '',
      ),
    );
    return DreamInsight(
      kind: DreamInsightKind.personalConnection,
      title: 'Önceki rüyalarla bağ',
      body: DreamAnalysisBeats.you(
        facts: facts,
        date: formatDate(match.previousDreamDate),
        sharedSymbols: match.sharedSymbols,
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
