/// Spoken form of a visible OR reply. Meaning stays; chrome does not.
library;

abstract final class OrSpeechTextPreprocessor {
  OrSpeechTextPreprocessor._();

  static String prepare(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) => m[1] ?? '',
    );
    text = text.replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'`{1,3}'), '');
    text = text.replaceAll(RegExp(r'[*_~]{1,3}'), '');
    text = text.replaceAll(_emoji, '');
    text = text.replaceAll('\u2026', '...');
    text = text.replaceAll(RegExp(r'\.{4,}'), '...');
    text = text.replaceAll(RegExp(r'!{2,}'), '!');
    text = text.replaceAll(RegExp(r'\?{2,}'), '?');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  static final _emoji = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]',
    unicode: true,
  );
}

/// Kept so existing imports keep compiling.
abstract final class OraclySpeechScript {
  OraclySpeechScript._();

  static String prepare(String raw) => OrSpeechTextPreprocessor.prepare(raw);
}
