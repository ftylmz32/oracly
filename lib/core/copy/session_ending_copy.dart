/// EPIC-015 — Session ending copy: peace, not pressure.
library;

import '../../features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import '../l10n/l10n.dart';

abstract final class SessionEndingCopy {
  SessionEndingCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get lastingReflectionTitle => _t('session.title');
  static String get footerWhisper => _t('session.footer');
  static String get saveConfirmation => _t('session.saved');
  static String get closingFallback => _t('session.closing');
  static String get affirmationFallback => _t('session.affirm');
  static String get noteDismiss => _t('session.note_dismiss');
  static String get noteHint => _t('session.note_hint');

  static String lastingReflection(AiReadingContent content) {
    final whisper = content.dailyAdvice.trim();
    if (whisper.isNotEmpty) return _completeSentence(whisper);
    return closingFallback;
  }

  static String affirmationBeat(AiReadingContent content) {
    final prompt = content.promptQuestion.trim();
    if (prompt.isNotEmpty) return _completeSentence(prompt);
    final spiritual = content.spiritualGuidance.trim();
    if (spiritual.isNotEmpty && spiritual.contains('?')) {
      for (final line in spiritual.split('\n')) {
        final trimmed = line.trim().replaceFirst(RegExp(r'^•\s*'), '');
        if (trimmed.isEmpty) continue;
        return _completeSentence(trimmed);
      }
    }
    return affirmationFallback;
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
