/// Card fact evidence for a Narrative Tarot request (Phase 3D.1A).
library;

import 'narrative_profile_slice.dart';

class TarotNarrativeCardEvidence {
  const TarotNarrativeCardEvidence({
    required this.canonicalCardId,
    required this.ritualCardId,
    required this.isReversed,
    required this.positionKey,
    required this.positionIndex,
    required this.displayName,
    required this.profileSlice,
    required this.imageAsset,
  });

  final String canonicalCardId;

  /// Required ritual deck identity (non-null).
  final int ritualCardId;
  final bool isReversed;
  final String positionKey;
  final int positionIndex;
  final String displayName;
  final TarotNarrativeProfileSlice profileSlice;
  final String imageAsset;
}
