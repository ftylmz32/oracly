/// Phase 5 — immutable signature spread position slot.
library;

import '../narrative/evidence/narrative_spread_semantics.dart';

class SignatureSpreadPosition {
  const SignatureSpreadPosition({
    required this.positionKey,
    required this.index,
    required this.role,
    required this.guidingQuestionKey,
    required this.displayLabelKey,
  });

  final String positionKey;
  final int index;
  final PositionRole role;
  final String guidingQuestionKey;
  final String displayLabelKey;
}
