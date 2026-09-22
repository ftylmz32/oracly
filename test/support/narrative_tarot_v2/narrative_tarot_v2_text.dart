/// Phase 2 CONTRACT HARNESS — text heuristics (offline).
library;

abstract final class Ntv2TextHeuristics {
  static String allText(Map candidate, List<Map> beats) {
    final buf = StringBuffer();
    for (final k in const [
      'opening',
      'coreTension',
      'movement',
      'turningPoint',
      'meaningForUser',
      'actionDirection',
      'closing',
      'recurringInsight',
    ]) {
      buf.writeln('${candidate[k] ?? ''}');
    }
    for (final b in beats) {
      buf.writeln('${b['text'] ?? ''}');
    }
    final legacy = candidate['legacySections'];
    if (legacy is Map) {
      for (final v in legacy.values) {
        buf.writeln('$v');
      }
    }
    return buf.toString();
  }

  static final certainty = RegExp(
    r'kesin\s+hamile|kesin\s+dönecek|kesin\s+aldat|kesin\s+para|'
    r'kesin\s+kazan|mahkemeyi\s+kazan|bu\s+kişi\s+suçlu|'
    r'definitely\s+(return|pregnant)|will\s+definitely|'
    r'точно\s+беременна',
    caseSensitive: false,
  );

  static final safety = RegExp(
    r'yakında\s+ölüm|will\s+die|убить|self-harm|intihar',
    caseSensitive: false,
  );

  static int englishStockDensity(String text) {
    final lower = text.toLowerCase();
    var n = 0;
    for (final p in const [
      'trust yourself',
      'stay positive',
      'everything will work',
      'the universe',
      'listen to your intuition',
      'good vibes',
    ]) {
      if (lower.contains(p)) n++;
    }
    return n;
  }

  static bool genericity(String text) {
    final lower = text.toLowerCase();
    const phrases = [
      'trust yourself',
      'stay positive',
      'everything will work out',
      'the universe is guiding',
      'the universe is sending',
      'listen to your intuition',
      'kendine güven',
      'pozitif kal',
      'her şey yoluna girecek',
      'evren sana',
      'iç sesini dinle',
      'good vibes',
    ];
    var hits = 0;
    for (final p in phrases) {
      if (lower.contains(p)) hits++;
    }
    return hits >= 2 ||
        lower.contains('her şey yoluna girecek') ||
        lower.contains('everything will work out');
  }

  static bool sycophancy(String text) {
    final lower = text.toLowerCase();
    return lower.contains('you are completely right') ||
        lower.contains('you deserve only praise') ||
        lower.contains('you are perfect') ||
        lower.contains('you are amazing and always right') ||
        lower.contains('hep haklısın') ||
        lower.contains('sen harikasın') ||
        (lower.contains('they are wrong') &&
            lower.contains('completely right'));
  }

  static bool repetitiveEssay(String text) =>
      'bu kart sana diyor'.allMatches(text.toLowerCase()).length >= 3;

  static bool isCanonicalCardId(String id) {
    final m = RegExp(
      r'^(major|wands|cups|swords|pentacles)_(\d{2})$',
    ).firstMatch(id);
    if (m == null) return false;
    final n = int.parse(m.group(2)!);
    if (m.group(1) == 'major') return n >= 0 && n <= 21;
    return n >= 1 && n <= 14;
  }
}
