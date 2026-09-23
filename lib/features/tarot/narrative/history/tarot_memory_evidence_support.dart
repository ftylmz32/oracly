/// Memory content + ranking helpers (Phase 4B).
library;

import 'tarot_connected_memory_models.dart';

abstract final class TarotMemoryEvidenceSupport {
  TarotMemoryEvidenceSupport._();

  static const maxEntryChars = 220;

  static double clamp01(double v) {
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  static double rankingScore({
    required double relevance,
    required double confidence,
    required DateTime occurredAt,
    required DateTime nowUtc,
  }) {
    final ageDays = nowUtc.difference(occurredAt.toUtc()).inSeconds / 86400.0;
    final recency = 1 / (1 + ageDays / 30);
    return relevance * 0.50 + recency * 0.30 + clamp01(confidence) * 0.20;
  }

  /// Prefix + clipped summary, or null if cannot fit one summary char.
  static String? buildContent(
    TarotConnectedMemoryRecord record,
    int remainingBudget,
  ) {
    final epi = record.epistemic.name.toUpperCase();
    final prefix = '[$epi][${record.sourceType.name}] ';
    final hardCap = remainingBudget < maxEntryChars
        ? remainingBudget
        : maxEntryChars;
    if (hardCap < prefix.length + 1) return null;

    var summary = record.summary.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (summary.isEmpty) return null;
    final maxSummary = hardCap - prefix.length;
    if (summary.length > maxSummary) {
      summary = summary.substring(0, maxSummary).trimRight();
    }
    if (summary.isEmpty) return null;
    return '$prefix$summary';
  }
}
