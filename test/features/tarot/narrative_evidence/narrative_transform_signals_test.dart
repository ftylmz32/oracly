import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/domain/reversed_transform_kind.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_transform_signals.dart';

void main() {
  group('NarrativeTransformPairSignals', () {
    test('exact-name keyword intersection locked', () {
      expect(NarrativeTransformPairSignals.exactNameKeywordIntersection, [
        'avoidance',
        'delay',
        'misdirection',
        'release',
      ]);
    });

    test('shared transforms sorted by enum index', () {
      final signals = NarrativeTransformPairSignals.from(
        leftTransforms: const [
          ReversedTransformKind.release,
          ReversedTransformKind.delay,
          ReversedTransformKind.avoidance,
        ],
        rightTransforms: const [
          ReversedTransformKind.avoidance,
          ReversedTransformKind.excess,
          ReversedTransformKind.delay,
        ],
        leftSemanticIds: const [],
        rightSemanticIds: const [],
      );
      expect(signals.sharedTransforms, [
        ReversedTransformKind.delay,
        ReversedTransformKind.avoidance,
      ]);
      expect(signals.effectiveSharedTransforms, signals.sharedTransforms);
      expect(signals.suppressedDualNameTransforms, isEmpty);
    });

    test('dual-name suppression when semantic id on BOTH sides', () {
      final signals = NarrativeTransformPairSignals.from(
        leftTransforms: const [
          ReversedTransformKind.delay,
          ReversedTransformKind.excess,
        ],
        rightTransforms: const [
          ReversedTransformKind.delay,
          ReversedTransformKind.distortion,
        ],
        leftSemanticIds: const [NarrativeKeywordIds.delay],
        rightSemanticIds: const [NarrativeKeywordIds.delay],
      );
      expect(signals.sharedTransforms, [ReversedTransformKind.delay]);
      expect(signals.suppressedDualNameTransforms, [
        ReversedTransformKind.delay,
      ]);
      expect(signals.effectiveSharedTransforms, isEmpty);
    });

    test('one-sided keyword does NOT suppress shared transform', () {
      final signals = NarrativeTransformPairSignals.from(
        leftTransforms: const [ReversedTransformKind.delay],
        rightTransforms: const [ReversedTransformKind.delay],
        leftSemanticIds: const [NarrativeKeywordIds.delay],
        rightSemanticIds: const [NarrativeKeywordIds.haste],
      );
      expect(signals.sharedTransforms, [ReversedTransformKind.delay]);
      expect(signals.suppressedDualNameTransforms, isEmpty);
      expect(signals.effectiveSharedTransforms, [ReversedTransformKind.delay]);
    });

    test('non-exact-name transforms never dual-suppress', () {
      final signals = NarrativeTransformPairSignals.from(
        leftTransforms: const [ReversedTransformKind.internalization],
        rightTransforms: const [ReversedTransformKind.internalization],
        leftSemanticIds: const [NarrativeKeywordIds.withdrawal],
        rightSemanticIds: const [NarrativeKeywordIds.withdrawal],
      );
      expect(signals.suppressedDualNameTransforms, isEmpty);
      expect(signals.effectiveSharedTransforms, [
        ReversedTransformKind.internalization,
      ]);
    });

    test('lists immutable', () {
      final signals = NarrativeTransformPairSignals.from(
        leftTransforms: const [ReversedTransformKind.delay],
        rightTransforms: const [ReversedTransformKind.delay],
        leftSemanticIds: const [],
        rightSemanticIds: const [],
      );
      expect(
        () => signals.sharedTransforms.add(ReversedTransformKind.excess),
        throwsUnsupportedError,
      );
    });
  });
}
