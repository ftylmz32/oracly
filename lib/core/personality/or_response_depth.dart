/// OR reply length — cap only, never padding. Intelligence picks among these.
library;

enum OrResponseDepth {
  /// 1–2 sentences — greetings, acknowledgments.
  veryShort,
  short,
  /// Medium — user-facing label DENGELİ / balanced.
  balanced,
  deep;

  static const storageKey = 'settings_or_response_depth';

  static const OrResponseDepth fallback = balanced;

  /// Settings / chips — intelligence may still pick [veryShort].
  static const preferenceValues = <OrResponseDepth>[
    short,
    balanced,
    deep,
  ];

  /// Alias for callers that say "medium".
  static const OrResponseDepth medium = balanced;

  int get rank => index;

  int get maxSentences => switch (this) {
        veryShort => 2,
        short => 4,
        balanced => 8,
        deep => 16,
      };

  int get voiceMaxSentences => switch (this) {
        veryShort => 2,
        short => 4,
        balanced => 6,
        deep => 8,
      };

  int get maxParagraphs => switch (this) {
        veryShort => 1,
        short => 2,
        balanced => 4,
        deep => 8,
      };

  OrResponseDepth get next => switch (this) {
        veryShort => short,
        short => balanced,
        balanced => deep,
        deep => short,
      };

  int sentenceCap({required bool spoken}) =>
      spoken ? voiceMaxSentences : maxSentences;

  int paragraphCap({required bool spoken}) {
    final paras = maxParagraphs;
    return spoken && paras > 4 ? 4 : paras;
  }

  /// Cap only. Never inflate a short reply.
  String cap(String text, {required bool spoken}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    return _trimParas(
      _trimSentences(trimmed, sentenceCap(spoken: spoken)),
      paragraphCap(spoken: spoken),
    );
  }

  String promptRule({required bool spoken}) {
    final max = sentenceCap(spoken: spoken);
    final floor = switch (this) {
      veryShort => '1–2',
      short => '1–4',
      balanced => '4–8',
      deep => '8–16',
    };
    final useful = this == deep
        ? ' Yararlıysa $floor cümle.'
        : ' $floor cümle yeter.';
    final voice = spoken ? ' Sesli yanıtta en fazla $max cümle.' : '';
    return 'Uzunluk tercihi: $name.$useful '
        'Daha kısa yeterse kısa bırak. Doldurma yok. '
        'Kişiliği veya üslubu değiştirme.$voice';
  }

  static OrResponseDepth parse(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'veryshort':
      case 'very_short':
      case 'çok kısa':
      case 'cok kisa':
        return veryShort;
      case 'short':
      case 'kisa':
      case 'kısa':
        return short;
      case 'deep':
      case 'derin':
        return deep;
      case 'medium':
      case 'balanced':
      case 'dengeli':
      default:
        return balanced;
    }
  }

  static String legacyCap(String cleaned, String trimmedUser) {
    if (trimmedUser.isEmpty || trimmedUser.length > 72) {
      return _trimParas(cleaned, 6);
    }
    if (trimmedUser.length <= 24) {
      return _trimParas(_trimSentences(cleaned, 2), 1);
    }
    return _trimParas(_trimSentences(cleaned, 3), 2);
  }

  static String _trimSentences(String text, int max) {
    final parts = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (parts.length <= max) return text;
    return parts.take(max).join(' ');
  }

  static String _trimParas(String text, int maxParas) {
    final paragraphs = text.split(RegExp(r'\n{2,}'));
    if (paragraphs.length <= maxParas) return text;
    return paragraphs.take(maxParas).join('\n\n');
  }
}
