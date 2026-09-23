/// Phase 5E — normalized shadow card after position / bridge validation.
library;

import '../narrative/evidence/narrative_spread_semantics.dart';

class SignatureSpreadShadowNormalizedCard {
  const SignatureSpreadShadowNormalizedCard({
    required this.ritualCardId,
    required this.canonicalCardId,
    required this.isReversed,
    required this.positionIndex,
    required this.positionKey,
    required this.role,
  });

  final int ritualCardId;
  final String canonicalCardId;
  final bool isReversed;
  final int positionIndex;
  final String positionKey;
  final PositionRole role;
}
