/// Phase 6E — session → shadow input (delegates to live shared mapping).
library;

import '../../domain/models/reading_session.dart';
import '../../signature_spreads/signature_spread_shadow_input.dart';
import '../live/narrative_tarot_live_session.dart';
import 'narrative_tarot_shadow_status.dart';

abstract final class NarrativeTarotShadowSession {
  NarrativeTarotShadowSession._();

  static NarrativeTarotShadowInputFailure? guard(ReadingSession session) {
    final fail = NarrativeTarotLiveSession.guard(session);
    if (fail == null) return null;
    return switch (fail) {
      NarrativeTarotLiveInputFailure.emptySessionId =>
        NarrativeTarotShadowInputFailure.emptySessionId,
      NarrativeTarotLiveInputFailure.emptyDrawnCards =>
        NarrativeTarotShadowInputFailure.emptyDrawnCards,
      NarrativeTarotLiveInputFailure.cardCountMismatch =>
        NarrativeTarotShadowInputFailure.cardCountMismatch,
      NarrativeTarotLiveInputFailure.outOfRangePosition =>
        NarrativeTarotShadowInputFailure.outOfRangePosition,
      NarrativeTarotLiveInputFailure.duplicatePosition =>
        NarrativeTarotShadowInputFailure.duplicatePosition,
      NarrativeTarotLiveInputFailure.missingPosition =>
        NarrativeTarotShadowInputFailure.missingPosition,
      NarrativeTarotLiveInputFailure.invalidRitualCard =>
        NarrativeTarotShadowInputFailure.invalidRitualCard,
      NarrativeTarotLiveInputFailure.positionKeyMismatch =>
        NarrativeTarotShadowInputFailure.positionKeyMismatch,
    };
  }

  static SignatureSpreadShadowInput toShadowInput({
    required ReadingSession session,
    required String readingId,
    required String languageCode,
  }) {
    return NarrativeTarotLiveSession.toLiveInput(
      session: session,
      readingId: readingId,
      languageCode: languageCode,
    );
  }
}
