/// Shared reversed-transform signals with dual-name suppression — Phase 3D.1B.
///
/// No numeric bonuses. Scorer consumes [effectiveSharedTransforms] in 3D.1C.
library;

import '../domain/narrative_keyword_ids.dart';
import '../domain/reversed_transform_kind.dart';

class NarrativeTransformPairSignals {
  const NarrativeTransformPairSignals._({
    required this.leftTransforms,
    required this.rightTransforms,
    required this.sharedTransforms,
    required this.suppressedDualNameTransforms,
    required this.effectiveSharedTransforms,
  });

  final List<ReversedTransformKind> leftTransforms;
  final List<ReversedTransformKind> rightTransforms;
  final List<ReversedTransformKind> sharedTransforms;
  final List<ReversedTransformKind> suppressedDualNameTransforms;
  final List<ReversedTransformKind> effectiveSharedTransforms;

  /// Pure structured transform intersection + exact-name dual suppression.
  factory NarrativeTransformPairSignals.from({
    required Iterable<ReversedTransformKind> leftTransforms,
    required Iterable<ReversedTransformKind> rightTransforms,
    required Iterable<String> leftSemanticIds,
    required Iterable<String> rightSemanticIds,
  }) {
    final left = _sortedUnique(leftTransforms);
    final right = _sortedUnique(rightTransforms);
    final leftSet = left.toSet();
    final rightSet = right.toSet();
    final shared = _sortedUnique(leftSet.intersection(rightSet));

    final leftSemantics = leftSemanticIds.toSet();
    final rightSemantics = rightSemanticIds.toSet();

    final suppressed = <ReversedTransformKind>[];
    final effective = <ReversedTransformKind>[];
    for (final t in shared) {
      final name = t.name;
      final dualName =
          NarrativeKeywordIds.all.contains(name) &&
          leftSemantics.contains(name) &&
          rightSemantics.contains(name);
      if (dualName) {
        suppressed.add(t);
      } else {
        effective.add(t);
      }
    }

    return NarrativeTransformPairSignals._(
      leftTransforms: List<ReversedTransformKind>.unmodifiable(left),
      rightTransforms: List<ReversedTransformKind>.unmodifiable(right),
      sharedTransforms: List<ReversedTransformKind>.unmodifiable(shared),
      suppressedDualNameTransforms: List<ReversedTransformKind>.unmodifiable(
        suppressed,
      ),
      effectiveSharedTransforms: List<ReversedTransformKind>.unmodifiable(
        effective,
      ),
    );
  }

  /// Transform enum names that also exist in NarrativeKeywordIds (rev 1).
  static List<String> get exactNameKeywordIntersection {
    final ids =
        ReversedTransformKind.values
            .map((t) => t.name)
            .where(NarrativeKeywordIds.all.contains)
            .toList()
          ..sort();
    return List<String>.unmodifiable(ids);
  }

  static List<ReversedTransformKind> _sortedUnique(
    Iterable<ReversedTransformKind> values,
  ) {
    final list = values.toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return list;
  }
}
