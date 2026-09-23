/// Present a completed tarot reading only after one successful gem commit.
library;

import 'dart:async';

import '../../../core/copy/resilience_copy.dart';
import '../../gems/services/paid_ai_operation_binder.dart';
import '../../gems/services/paid_ai_operation_id.dart';
import '../copy/tarot_l10n.dart';
import '../domain/models/reading_session.dart';
import '../presentation/widgets/ai_reading/ai_reading_content.dart';
import '../services/tarot_interpretation_service.dart';
import 'tarot_reading_charge.dart';

class TarotReadingCompletion {
  TarotReadingCompletion({
    required this._charge,
    TarotInterpretationService? interpretation,
  }) : _interpretation = interpretation ?? TarotInterpretationService();

  final TarotReadingCharge _charge;
  final TarotInterpretationService _interpretation;

  static const loadTimeout = Duration(seconds: 45);

  static String get fallbackReason => TarotL10n.fallbackLoad;

  /// Loads interpretation, then charges once for [interpretation] delivery.
  /// Safety preflight is free and runs before affordability.
  /// Null → do not show a completed reading. [shouldCommit] false skips spend.
  Future<AiReadingContent?> complete(
    ReadingSession session, {
    Future<AiReadingContent> Function()? load,
    bool Function()? shouldCommit,
    Duration timeout = loadTimeout,
  }) async {
    if (session.drawnCards.isEmpty) return null;

    // Safety help must not depend on gems, wallet, or provider.
    final safety = _interpretation.safetyResponseIfNeeded(session);
    if (safety != null) return safety;

    if (!_charge.canAfford(session.spread, sessionId: session.id)) {
      return null;
    }
    AiReadingContent content;
    try {
      // Session id is the sole provider idempotency identity for this reading.
      final key = PaidAiOperationId.fromExisting('tarot', session.id);
      content = await PaidAiOperationBinder.runWithKey(
        key,
        () => (load ?? () => _interpretation.generateContent(session))(),
      ).timeout(timeout);
    } catch (_) {
      if (_charge.alreadyCharged(session.id)) {
        return _interpretation.emergencyFallback(
          session,
          reason: fallbackReason,
        );
      }
      return null;
    }
    if (!_usable(content)) {
      if (_charge.alreadyCharged(session.id)) {
        return _interpretation.emergencyFallback(
          session,
          reason: ResilienceCopy.aiEmptyResponse,
        );
      }
      return null;
    }
    if (shouldCommit != null && !shouldCommit()) return null;

    // Safety via load path (defensive) — never mark provider OK or settle.
    if (content.deliveryKind == TarotReadingDeliveryKind.safety) {
      return content;
    }

    // Recovery is valid only for an already-settled paid reading.
    if (content.deliveryKind == TarotReadingDeliveryKind.recovery) {
      if (_charge.alreadyCharged(session.id)) return content;
      return null;
    }

    await _charge.markProviderOk(session.id, spread: session.spread);
    if (!await _charge.commit(session.id, spread: session.spread)) {
      await _charge.abandon(session.id, spread: session.spread);
      return null;
    }
    return content;
  }

  static bool _usable(AiReadingContent content) {
    return content.generalMeaning.trim().isNotEmpty ||
        (content.fullInterpretation ?? '').trim().isNotEmpty;
  }
}
