/// EPIC-015 — Session ending copy: peace, not pressure.
library;

import '../../features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';

/// Quiet language for how sessions conclude — a feeling, not a feature.
abstract final class SessionEndingCopy {
  SessionEndingCopy._();

  /// Title for the final reflection block (replaces "Kozmik Mesaj").
  static const lastingReflectionTitle = 'Son Yansıma';

  /// Shown under footer actions — permission to leave.
  static const footerWhisper =
      'Bu an seninle kalabilir. Acele etme — huzurla ayrılabilirsin.';

  /// When journal save succeeds.
  static const saveConfirmation =
      'Bu yansıma günlüğünde — istediğin zaman geri bakabilirsin.';

  /// Gentle fallback when no synthesized closing exists.
  static const closingFallback =
      'Bu birkaç dakika kendi iç sesine alan açtıysa, yeterli. '
      'Ne hissediyorsan, o değerlidir.';

  /// Pre-closing beat — not duplicated advice.
  static const affirmationFallback =
      'Bir an durup ne hissettiğine bakmak, bazen en net cevaptır.';

  /// Journal note sheet — dismiss without guilt.
  static const noteDismiss = 'Şimdilik geç';

  /// Journal note hint — revisit anytime.
  static const noteHint =
      'Örn. "Bugün bu doğru hissettirdi." — istediğin zaman geri dönebilirsin.';

  /// Resolves the one sentence meant to stay with the user.
  static String lastingReflection(AiReadingContent content) {
    final closing = content.closingMessage.trim();
    if (closing.isNotEmpty) {
      return _completeSentence(closing);
    }
    return closingFallback;
  }

  /// Resolves the softer beat before the final reflection.
  static String affirmationBeat(AiReadingContent content) {
    final closing = content.closingMessage.trim();
    if (closing.isNotEmpty) {
      return _firstSentence(closing);
    }

    final spiritual = content.spiritualGuidance.trim();
    for (final line in spiritual.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•')) {
        return trimmed.substring(1).trim();
      }
    }

    final summary = content.generalMeaning.trim();
    if (summary.isNotEmpty) {
      return _firstSentence(summary);
    }

    return affirmationFallback;
  }

  static String _firstSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return affirmationFallback;
    final dot = trimmed.indexOf('.');
    if (dot > 0 && dot < trimmed.length - 1) {
      return _completeSentence(trimmed.substring(0, dot + 1));
    }
    return _completeSentence(trimmed);
  }

  static String _completeSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.endsWith('…')) return trimmed;
    if (trimmed.endsWith('.') ||
        trimmed.endsWith('!') ||
        trimmed.endsWith('?')) {
      return trimmed;
    }
    return '$trimmed.';
  }
}
