/// Spoken rhythm only. The on-screen reply is never rewritten by this.
library;

import 'or_speech_headings.dart';
import 'or_speech_numbers.dart';
import 'or_speech_questions.dart';
import 'or_speech_text_preprocessor.dart';

abstract final class OrSpeechProsody {
  OrSpeechProsody._();

  static const maxSpokenChars = 460;
  static const _ellipsis = '\uE000';

  static String prepare(String raw) {
    var text = _markEmphasis(raw);
    text = _spokenHeadings(text);
    text = OrSpeechTextPreprocessor.prepare(text);
    text = OrSpeechNumbers.prepare(text);
    text = text.replaceAll(RegExp(r'\.{4,}'), '...');
    text = text.replaceAll(RegExp(r'(\.\.\.){2,}'), '...');
    text = _joinBrokenLines(text);
    text = OrSpeechQuestions.restore(text);
    text = _groupThoughts(text);
    text = _shorten(text);
    return text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  }

  static String _markEmphasis(String raw) {
    return raw.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) {
        final word = (m[1] ?? '').trim();
        if (word.isEmpty || word.split(' ').length > 4) return word;
        return ', $word,';
      },
    );
  }

  static String _spokenHeadings(String raw) {
    return raw.replaceAllMapped(
      RegExp(r'^#{1,6}\s*(.+)$', multiLine: true),
      (m) => OrSpeechHeadings.spokenLine(m[1] ?? ''),
    );
  }

  static String _joinBrokenLines(String text) {
    return text
        .split(RegExp(r'\n{2,}'))
        .map(_oneLine)
        .where((block) => block.isNotEmpty)
        .join(' ... ');
  }

  static String _oneLine(String block) {
    return block
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join(' ');
  }

  static String _groupThoughts(String text) {
    var guarded = text.replaceAll('...', _ellipsis);
    final chunks = guarded
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (chunks.length < 2) return text;
    final out = <String>[];
    var i = 0;
    while (i < chunks.length) {
      var current = chunks[i];
      var joined = 1;
      while (i + 1 < chunks.length &&
          joined < 3 &&
          _shortClause(current) &&
          _shortClause(chunks[i + 1]) &&
          !_isQuestion(current) &&
          !_isQuestion(chunks[i + 1]) &&
          !current.contains(_ellipsis)) {
        current = _attach(current, chunks[i + 1]);
        i++;
        joined++;
      }
      out.add(current);
      i++;
    }
    return out.join(' ').replaceAll(_ellipsis, '...');
  }

  static bool _isQuestion(String value) =>
      value.contains('?') || value.contains(_ellipsis);

  static bool _shortClause(String value) {
    final words = value
        .replaceAll(_ellipsis, ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return words.length <= 8;
  }

  static String _attach(String left, String right) {
    final lead = left.replaceAll(RegExp(r'\.\s*$'), '');
    final next = right[0].toLowerCase() + right.substring(1);
    return '$lead, $next';
  }

  static String _shorten(String text) {
    if (text.length <= maxSpokenChars) return text;
    final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    final buf = StringBuffer();
    for (final part in parts) {
      final next = buf.isEmpty ? part : '${buf.toString()} $part';
      if (next.length > maxSpokenChars && buf.isNotEmpty) break;
      buf
        ..clear()
        ..write(next);
      if (buf.length >= maxSpokenChars) break;
    }
    final spoken = buf.toString().trim();
    return spoken.isEmpty ? text.substring(0, maxSpokenChars).trim() : spoken;
  }
}
