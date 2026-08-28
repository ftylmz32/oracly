/// Only a real asked question becomes the reading's spine.
library;

import '../../ai/services/prompt_sanitizer.dart';

abstract final class ReadingQuestion {
  ReadingQuestion._();

  static const maxLength = 280;

  static const _generic = {
    'genel rehberlik',
    'genel',
    'guidance',
    'general guidance',
    'общая опора',
    'общее',
  };

  static String sanitize(String? raw) {
    var text = PromptSanitizer.sanitize(raw ?? '');
    if (text.length > maxLength) text = text.substring(0, maxLength);
    return text.trim();
  }

  static String? real(String? raw) {
    final text = sanitize(raw);
    if (text.isEmpty) return null;
    if (_generic.contains(text.toLowerCase())) return null;
    return text;
  }
}
