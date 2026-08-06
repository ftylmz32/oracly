import '../models/tarot_card.dart';

/// Structured interpretation content derived from AI reading + card data.
class TarotReadingSections {
  const TarotReadingSections({
    required this.cardMessage,
    required this.innerMeaning,
    required this.guidance,
    required this.dailyReflection,
  });

  final String cardMessage;
  final String innerMeaning;
  final String guidance;
  final String dailyReflection;
}

class TarotReadingInsights {
  const TarotReadingInsights({
    required this.energy,
    required this.theme,
    required this.guidance,
  });

  final String energy;
  final String theme;
  final String guidance;
}

class TarotReadingParser {
  TarotReadingParser._();

  static TarotReadingSections parseSections(
    String reading,
    TarotCard primary,
  ) {
    final chunks = _splitIntoChunks(reading);
    if (chunks.isEmpty) {
      return _fallbackFromCard(primary);
    }

    if (chunks.length == 1) {
      final parts = _splitSentences(chunks.first);
      return TarotReadingSections(
        cardMessage: parts.isNotEmpty ? parts.first : primary.summary,
        innerMeaning: parts.length > 1
            ? parts.sublist(1, (parts.length / 2).ceil()).join(' ')
            : primary.meaning,
        guidance: parts.length > 2
            ? parts.sublist((parts.length / 2).ceil(), parts.length - 1).join(' ')
            : _guidanceFallback(reading, primary),
        dailyReflection: parts.length > 1
            ? parts.last
            : 'Bugün kartın mesajını kalbinde taşı ve nazikçe ilerle.',
      );
    }

    return TarotReadingSections(
      cardMessage: chunks[0],
      innerMeaning: chunks.length > 1 ? chunks[1] : primary.meaning,
      guidance: chunks.length > 2 ? chunks[2] : _guidanceFallback(reading, primary),
      dailyReflection: chunks.length > 3
          ? chunks.sublist(3).join('\n\n')
          : chunks.last,
    );
  }

  static TarotReadingInsights parseInsights(
    TarotCard primary,
    String reading,
  ) {
    return TarotReadingInsights(
      energy: _energyLabel(primary),
      theme: primary.keywords.isNotEmpty
          ? primary.keywords.first
          : (primary.element ?? 'Ruhsal Yol'),
      guidance: primary.keywords.length > 1
          ? primary.keywords[1]
          : _guidanceKeyword(reading, primary),
    );
  }

  static List<String> _splitIntoChunks(String text) {
    return text
        .split(RegExp(r'\n\s*\n'))
        .map((s) => s.trim())
        .where((s) => s.length > 8)
        .toList();
  }

  static List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?…])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 12)
        .toList();
  }

  static TarotReadingSections _fallbackFromCard(TarotCard card) {
    return TarotReadingSections(
      cardMessage: card.summary,
      innerMeaning: card.meaning,
      guidance: _guidanceFallback('', card),
      dailyReflection:
          'Bugün ${card.name} enerjisi seninle — niyetini koru ve iç sesine güven.',
    );
  }

  static String _guidanceFallback(String reading, TarotCard card) {
    if (reading.trim().length > 40) {
      final sentences = _splitSentences(reading);
      if (sentences.length >= 2) return sentences[sentences.length - 2];
    }
    return card.meaning.split('.').first.trim();
  }

  static String _guidanceKeyword(String reading, TarotCard card) {
    if (card.element != null) return card.element!;
    if (reading.contains('yol')) return 'Yol Haritası';
    return 'Rehberlik';
  }

  static String _energyLabel(TarotCard card) {
    final score = card.energyEffect + card.intuitionEffect;
    if (score >= 4) return 'Yüksek Enerji';
    if (score >= 1) return 'Dengeli Akış';
    if (score <= -2) return 'Sakin Dönüşüm';
    return 'Derin Sezgi';
  }
}
