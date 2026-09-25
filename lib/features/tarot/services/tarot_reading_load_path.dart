/// ReadingScreen / E2E shared load decision — CASE A/B/C (Phase 8.1).
library;

import '../domain/models/reading_session.dart';
import '../economy/tarot_reading_charge.dart';
import '../economy/tarot_reading_completion.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import 'tarot_session_interpretation_replay.dart';

/// Resolves interpretation for display without confusing content with payment.
abstract final class TarotReadingLoadPath {
  TarotReadingLoadPath._();

  /// CASE A — no body → normal generate via [completion].
  /// CASE B — body, not charged → [completion] charges; [load] returns replay.
  /// CASE C — body + charged → return replay; no provider, no charge.
  static Future<AiReadingContent?> resolve({
    required ReadingSession session,
    required TarotReadingCharge charge,
    required TarotReadingCompletion completion,
    required Future<AiReadingContent> Function() generate,
    bool Function()? shouldCommit,
    Duration? timeout,
  }) {
    final replay = TarotSessionInterpretationReplay.tryBuild(session);
    if (replay == null) {
      return completion.complete(
        session,
        load: generate,
        shouldCommit: shouldCommit,
        timeout: timeout ?? TarotReadingCompletion.loadTimeout,
      );
    }
    if (charge.alreadyCharged(session.id)) {
      return Future<AiReadingContent?>.value(replay);
    }
    return completion.complete(
      session,
      load: () async => replay,
      shouldCommit: shouldCommit,
      timeout: timeout ?? TarotReadingCompletion.loadTimeout,
    );
  }
}
