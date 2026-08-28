/// RC-002 — Tone guard for AI conversation responses.
library;

import '../../../core/personality/or_core.dart';
import '../../../core/personality/or_response_depth.dart';
import '../../../core/reading/robotic_language_rewrite.dart';
import '../../../core/reading/ai_output_quality_context.dart';
import '../../../core/reading/ai_output_quality_gate.dart';
import '../../../core/reading/ai_output_quality_kind.dart';
import '../../../core/reading/ai_output_quality_logger.dart';
import '../../insights/services/reflective_intelligence.dart';
import 'conversation_empathy_guard.dart';
import 'conversation_filler_guard.dart';
import 'conversation_patronizing_guard.dart';
import 'conversation_question_guard.dart';

abstract final class ConversationResponseGuard {
  ConversationResponseGuard._();

  static const _kind = AiOutputQualityKind.companion;

  /// Softens certainty. Length is a cap only when [depth] is set.
  static String polish(
    String text, {
    String userMessage = '',
    bool hasMemoryEvidence = false,
    bool allowTrailingQuestion = true,
    OrResponseDepth? depth,
    bool spoken = false,
    String? priorAssistant,
  }) {
    final softened = ReflectiveIntelligence.soften(text.trim());
    if (softened.isEmpty) return softened;
    var cleaned = ConversationFillerGuard.shape(
      ConversationPatronizingGuard.shape(
        ConversationEmpathyGuard.shape(softened),
      ),
    );
    cleaned = _stripForcedEmpathy(cleaned);
    cleaned = ConversationQuestionGuard.shape(
      cleaned,
      allowTrailingQuestion: allowTrailingQuestion,
      priorAssistant: priorAssistant,
    );
    if (cleaned.isEmpty) return 'Ne oldu?';
    final shapedRaw = depth != null
        ? depth.cap(cleaned, spoken: spoken)
        : OrResponseDepth.legacyCap(cleaned, userMessage.trim());
    var shaped = RoboticLanguageRewrite.bounded(shapedRaw);
    shaped = _groundInUserWords(shaped, userMessage);
    final check = AiOutputQualityGate.validate(
      shaped,
      kind: _kind,
      context: AiOutputQualityContext(hasMemoryEvidence: hasMemoryEvidence),
    );
    if (check.isAcceptable) return shaped;
    if (check.category != null) {
      AiOutputQualityLogger.logFailure(
        operationId: 'companion.polish',
        category: check.category!,
        attempt: 1,
      );
    }
    return 'Ne oldu?';
  }

  /// Keeps short probes from sounding generic — cites a real user word.
  static String _groundInUserWords(String reply, String userMessage) {
    final r = reply.trim();
    final u = userMessage.trim();
    if (u.length < 16 || r.length >= 72) return r;
    final token = _concreteUserToken(u);
    if (token == null) return r;
    if (r.toLowerCase().contains(token)) return r;
    return '“$token” dediğin yer duruyor. $r';
  }

  static String? _concreteUserToken(String message) {
    final lower = message.toLowerCase();
    // Longer / ritual words first so "işimle" + "kahve" cites kahve, not iş.
    // Keep "iş" ahead of "sıkış" so job threads ground on topic, not feeling.
    const long = [
      'kahve', 'fincan', 'enerji', 'ilişki', 'mesafe', 'yalnız',
      'korku', 'karar', 'eşik', 'sabah', 'rüya', 'kart', 'yavaş', 'adım',
      'nazik', 'tempo', 'iş', 'sıkış',
    ];
    for (final t in long) {
      if (t == 'iş') {
        if (RegExp(r'(?:^|[^a-züğışöçâîû0-9])iş(?:[^a-züğışöçâîû0-9]|$)')
            .hasMatch(lower)) {
          return t;
        }
        continue;
      }
      if (lower.contains(t)) return t;
    }
    const short = ['ses', 'kapı'];
    for (final t in short) {
      if (RegExp('(?:^|[^a-züğışöçâîû0-9])$t(?:[^a-züğışöçâîû0-9]|\$)')
          .hasMatch(lower)) {
        return t;
      }
    }
    final words = lower
        .split(RegExp(r'[^a-züğışöçâîû0-9]+'))
        .where((w) => w.length >= 4)
        .toList();
    if (words.isEmpty) return null;
    return words.first;
  }

  static String _stripForcedEmpathy(String text) {
    var out = text.trim();
    if (out.isEmpty) return out;
    // Empathy sentences already shaped; nuke only if script still dominates.
    if (OrCore.looksMetaAi(out)) return 'Ne oldu?';
    if (OrCore.looksPatronizing(out)) {
      final shaped = ConversationPatronizingGuard.shape(out);
      return shaped.isEmpty ? 'Ne oldu?' : shaped;
    }
    if (OrCore.looksTherapistScript(out)) {
      final shaped = ConversationEmpathyGuard.shape(out);
      return shaped.isEmpty ? 'Ne oldu?' : shaped;
    }
    return out;
  }
}
