/// Dream Phase 4A — prior-Dream evidence for the current dream.
///
/// Pure and deterministic. Only evidence the CURRENT dream holds is looked
/// up; a prior Dream counts once per key; a prior Dream whose stored text
/// would safety-route today is left out (never deleted).
///
/// Ordering: more distinct prior Dreams first, then the most recent last
/// sighting, then kind order, then key — no scores, no randomness.
library;

import '../models/dream.dart';
import '../safety/dream_safety_policy.dart';
import 'dream_history_evidence.dart';
import 'dream_history_identity.dart';

abstract final class DreamHistoryBuilder {
  DreamHistoryBuilder._();

  /// Newest analyzed prior Dreams scanned per request.
  static const maxScanned = 40;

  /// Evidence items sent to the provider.
  static const maxEvidence = 5;

  /// Prior Dream ids kept per evidence item.
  static const maxPriorIds = 3;

  static DreamHistoryContext build({
    required Dream current,
    required Iterable<Dream> saved,
    required String language,
  }) {
    final wanted = DreamHistoryIdentity.entries(current, language);
    if (wanted.isEmpty) return DreamHistoryContext.empty;
    final ids = <String>{current.id};
    final priors = [
      for (final dream in saved)
        if (dream.isAnalyzed &&
            dream.recordedAt.isBefore(current.recordedAt) &&
            ids.add(dream.id) &&
            !_sensitive(dream))
          dream,
    ]..sort(_newestFirst);

    final hits = <String, List<Dream>>{};
    for (final prior in priors.take(maxScanned)) {
      for (final key in DreamHistoryIdentity.entries(prior, language).keys) {
        if (wanted.containsKey(key)) (hits[key] ??= []).add(prior);
      }
    }
    final evidence = [
      for (final MapEntry(:key, value: dreams) in hits.entries)
        DreamHistoryEvidence(
          kind: wanted[key]!.kind,
          canonicalKey: key,
          displayLabel: wanted[key]!.label,
          priorDreamCount: dreams.length,
          priorDreamIds: [for (final d in dreams.take(maxPriorIds)) d.id],
          firstSeenAt: dreams.last.recordedAt,
          lastSeenAt: dreams.first.recordedAt,
        ),
    ]..sort(_strongestFirst);

    // One observation told twice (the symbol "Ev" and the place "Ev") is
    // one item: the stronger/earlier-ordered one stays.
    final labels = <String>{};
    return DreamHistoryContext(List.unmodifiable([
      for (final item in evidence)
        if (labels.add(item.displayLabel.toLowerCase())) item,
    ].take(maxEvidence)));
  }

  static bool _sensitive(Dream dream) =>
      DreamSafetyPolicy.forDream(
        narrative: dream.narrative,
        entry: dream.entry,
        tags: dream.tags,
      ) !=
      null;

  static int _newestFirst(Dream a, Dream b) {
    final byDate = b.recordedAt.compareTo(a.recordedAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  static int _strongestFirst(DreamHistoryEvidence a, DreamHistoryEvidence b) {
    final byCount = b.priorDreamCount.compareTo(a.priorDreamCount);
    if (byCount != 0) return byCount;
    final byRecency = b.lastSeenAt.compareTo(a.lastSeenAt);
    if (byRecency != 0) return byRecency;
    final byKind = a.kind.index.compareTo(b.kind.index);
    return byKind != 0 ? byKind : a.canonicalKey.compareTo(b.canonicalKey);
  }
}
