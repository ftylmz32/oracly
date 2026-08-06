/// OR-1110 — Prompt sanitization for safe AI input.
library;

abstract final class PromptSanitizer {
  PromptSanitizer._();

  static const _maxLength = 8000;

  static String sanitize(String input) {
    var text = input.trim();
    if (text.length > _maxLength) {
      text = text.substring(0, _maxLength);
    }
    // Strip control characters except newline/tab.
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    return text;
  }

  static bool isValid(String input) {
    final s = sanitize(input);
    return s.isNotEmpty && s.length >= 2;
  }
}
