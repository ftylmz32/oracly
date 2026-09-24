/// Phase 6E/6F — live-launch Classical spread set (delegates to live package).
library;

import '../../domain/models/tarot_spread.dart';
import '../live/narrative_tarot_live_spreads.dart';

/// QA/shadow alias — production routing uses [NarrativeTarotLiveSpreads].
abstract final class NarrativeTarotShadowLaunch {
  NarrativeTarotShadowLaunch._();

  static const spreads = NarrativeTarotLiveSpreads.spreads;

  static bool isLiveLaunchCandidate(TarotSpreadType type) =>
      NarrativeTarotLiveSpreads.isLiveLaunchCandidate(type);

  static String narrativeSpreadId(TarotSpreadType type) =>
      NarrativeTarotLiveSpreads.narrativeSpreadId(type);
}
