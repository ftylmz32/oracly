/// Restore Turkish question intonation. Speech-only — never shown.
library;

abstract final class OrSpeechQuestions {
  OrSpeechQuestions._();

  static String restore(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map(ifNeeded)
        .join(' ');
  }

  static String ifNeeded(String part) {
    final value = part.trim();
    if (value.isEmpty || value.contains('?')) return value;
    if (!_looksLikeQuestion(value)) return value;
    return '${value.replaceAll(RegExp(r'\.\s*$'), '')}?';
  }

  static bool _looksLikeQuestion(String value) {
    return _particle.hasMatch(value) || _opens.hasMatch(value);
  }

  static final _particle = RegExp(
    r'(?:değil\s+mi|acaba|(?:^|\s)m[ıiuü]|mısın|misin|musun|müsün|'
    r'mısınız|misiniz|musunuz|müsünüz|mıyım|miyim|muyum|müyüm|'
    r'mıyız|miyiz|muyuz|müyüz|mıydı|miydi|muydu|müydü|'
    r'mıdır|midir|mudur|müdür|nedir|nasılsınız|nasılsın|'
    r'ne yapardın|ne dersin)\s*\.?$',
    caseSensitive: false,
  );

  static final _opens = RegExp(
    r'^(?:nasıl|neden(?!\s+sonra)|niçin|acaba)\b',
    caseSensitive: false,
  );
}
