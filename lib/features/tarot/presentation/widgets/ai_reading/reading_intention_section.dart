/// Picks the single intention block for the result stack.
library;

import '../../../copy/tarot_polish_copy.dart';
import 'ai_reading_content.dart';

abstract final class ReadingIntentionSection {
  ReadingIntentionSection._();

  static (String title, String body)? of(AiReadingContent content) {
    final theme = content.readingTheme;
    if (_is(theme, const ['love', 'aşk']) && content.love.trim().isNotEmpty) {
      return (TarotPolishCopy.loveTitle, content.love);
    }
    if (_is(theme, const ['career', 'kariyer']) &&
        content.career.trim().isNotEmpty) {
      return (TarotPolishCopy.careerTitle, content.career);
    }
    if (_is(theme, const ['daily', 'günlük']) &&
        content.spiritualGuidance.trim().isNotEmpty) {
      return (TarotPolishCopy.dailyTitle, content.spiritualGuidance);
    }
    if (_is(theme, const ['general', 'genel', 'money']) &&
        content.money.trim().isNotEmpty) {
      return (TarotPolishCopy.generalTitle, content.money);
    }
    if (content.love.trim().isNotEmpty) {
      return (TarotPolishCopy.loveTitle, content.love);
    }
    if (content.career.trim().isNotEmpty) {
      return (TarotPolishCopy.careerTitle, content.career);
    }
    if (content.spiritualGuidance.trim().isNotEmpty) {
      return (TarotPolishCopy.dailyTitle, content.spiritualGuidance);
    }
    if (content.money.trim().isNotEmpty) {
      return (TarotPolishCopy.generalTitle, content.money);
    }
    return null;
  }

  static bool _is(String? theme, List<String> keys) {
    final value = theme?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return false;
    return keys.any((key) => value == key || value.contains(key));
  }
}
