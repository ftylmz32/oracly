/// Narrative Tarot V2 — upright/reversed orientation slice.
library;

import '../../../../core/l10n/l10n_triple.dart';
import 'reversed_transform_kind.dart';

class NarrativeOrientationProfile {
  const NarrativeOrientationProfile({
    required this.expression,
    required this.transforms,
    required this.keywordIds,
  });

  final L10nTriple expression;
  final List<ReversedTransformKind> transforms;
  final List<String> keywordIds;
}
