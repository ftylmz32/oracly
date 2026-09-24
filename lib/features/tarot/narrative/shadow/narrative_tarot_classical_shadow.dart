/// Phase 6E — Classical dual-run shadow evaluator (pure, QA-only).
library;

import '../../../../core/l10n/app_locale.dart';
import '../../../../core/safety/sensitive_topic_gate.dart';
import '../../domain/models/reading_session.dart';
import '../history/tarot_historical_models.dart';
import 'narrative_tarot_shadow_launch.dart';
import 'narrative_tarot_shadow_pipeline.dart';
import 'narrative_tarot_shadow_result.dart';
import 'narrative_tarot_shadow_session.dart';
import 'narrative_tarot_shadow_status.dart';

/// Pure Classical dual-run harness. No network / storage / clock / billing.
abstract final class NarrativeTarotClassicalShadow {
  NarrativeTarotClassicalShadow._();

  static NarrativeTarotShadowResult evaluate({
    required ReadingSession session,
    required String readingId,
    required String languageCode,
    TarotHistoricalSnapshot? history,
    String? currentOwnerId,
    bool privacyBlocked = false,
    DateTime? now,
  }) {
    if (session.id.trim().isEmpty) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.invalidSession,
        inputFailure: NarrativeTarotShadowInputFailure.emptySessionId,
      );
    }
    if (readingId.trim().isEmpty) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.invalidSession,
        inputFailure: NarrativeTarotShadowInputFailure.emptyReadingId,
      );
    }
    if (!NarrativeTarotShadowLaunch.isLiveLaunchCandidate(session.spread)) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.notLiveLaunchCandidate,
      );
    }
    final inputFail = NarrativeTarotShadowSession.guard(session);
    if (inputFail != null) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.invalidSession,
        inputFailure: inputFail,
      );
    }
    if (SensitiveTopicGate.maybeRespond(session.intention.text) != null) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.safetyBlocked,
      );
    }
    return NarrativeTarotShadowPipeline.build(
      session: session,
      readingId: readingId,
      languageCode: AppLocale.normalize(languageCode),
      history: history,
      currentOwnerId: currentOwnerId,
      privacyBlocked: privacyBlocked,
      now: now,
    );
  }
}
