/// Speech-only labels. Visible markdown headings stay as written.
library;

abstract final class OrSpeechHeadings {
  OrSpeechHeadings._();

  static const _sides = {
    'aşk',
    'iş',
    'kariyer',
    'para',
    'sağlık',
    'genel',
    'uyarı',
    'özet',
    'ilişki',
    'enerji',
  };

  static String spokenLine(String raw) {
    final line = raw.trim();
    if (line.isEmpty || line.length > 28) return line;
    final words = line.split(RegExp(r'\s+'));
    if (words.length > 3) return line;
    final lower = _trLower(line);
    if (!_looksLikeLabel(line, lower)) return line;
    final title = _title(lower);
    if (_sides.contains(lower)) return '$title tarafında,';
    return '$title.';
  }

  static bool _looksLikeLabel(String line, String lower) {
    if (_sides.contains(lower)) return true;
    final letters = line.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]'), '');
    if (letters.length < 3) return false;
    return letters == letters.toUpperCase();
  }

  static String _trLower(String value) => value
      .replaceAll('I', 'ı')
      .replaceAll('İ', 'i')
      .toLowerCase();

  static String _title(String lower) {
    if (lower.isEmpty) return lower;
    const map = {
      'i': 'İ',
      'ı': 'I',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ö': 'Ö',
      'ç': 'Ç',
    };
    final first = lower.substring(0, 1);
    return '${map[first] ?? first.toUpperCase()}${lower.substring(1)}';
  }
}
