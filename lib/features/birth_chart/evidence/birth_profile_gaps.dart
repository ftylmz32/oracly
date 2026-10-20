/// Which saved birth answers are still genuinely missing.
library;

import '../models/birth_profile.dart';
import 'birth_evidence.dart';

abstract final class BirthProfileGaps {
  BirthProfileGaps._();

  /// Place is worth asking for only when it was never given and the user did
  /// not explicitly continue without it. Unknown birth time is never asked
  /// again: the reduced chart already covers it.
  static bool needsPlace(BirthProfile profile) =>
      !profile.birthPlaceUnknownConfirmed &&
      !BirthEvidence.fromProfile(profile).hasValidPlaceEvidence;
}
