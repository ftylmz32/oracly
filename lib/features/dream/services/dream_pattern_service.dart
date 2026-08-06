/// SPRINT-001 — Detect genuine patterns across stored dreams.
library;

import '../models/dream.dart';
import '../models/dream_insight.dart';

class DreamPatternMatch {
  const DreamPatternMatch({
    required this.sharedSymbols,
    required this.sharedTags,
    required this.previousDreamId,
    required this.previousDreamDate,
    required this.narrativeExcerpt,
  });

  final List<String> sharedSymbols;
  final List<String> sharedTags;
  final String previousDreamId;
  final DateTime previousDreamDate;
  final String narrativeExcerpt;
}

class DreamPatternService {
  const DreamPatternService();

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
        final excerpt = prior.narrative.length > 72
            ? '${prior.narrative.substring(0, 72)}…'
            : prior.narrative;
        best = DreamPatternMatch(
          sharedSymbols: sharedSymbols.map(_titleCase).toList(),
          sharedTags: sharedTags,
          previousDreamId: prior.id,
          previousDreamDate: prior.recordedAt,
          narrativeExcerpt: excerpt,
        );
      }
    }

    return best;
  }

  DreamInsight? buildConnectionInsight(DreamPatternMatch? match) {
    if (match == null) return null;

    final parts = <String>[];
    if (match.sharedSymbols.isNotEmpty) {
      parts.add('ortak semboller: ${match.sharedSymbols.join(', ')}');
    }
    if (match.sharedTags.isNotEmpty) {
      parts.add('ortak etiketler: ${match.sharedTags.join(', ')}');
    }

    final dateLabel = _formatDate(match.previousDreamDate);
    return DreamInsight(
      kind: DreamInsightKind.personalConnection,
      title: 'Önceki rüyalarla bağ',
      body:
          '$dateLabel tarihli rüyanda ${parts.join('; ')}. '
          'Bu tekrarlar bilinçaltının aynı temaya döndüğünü düşündürebilir — '
          'kesin bir anlam iddia etmiyoruz; sadece dikkat çekmek istedik.',
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d.$m.${date.year}';
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
