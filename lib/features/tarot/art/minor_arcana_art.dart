/// Minor Arcana artwork paths + Flutter chrome labels.
library;

class MinorChrome {
  const MinorChrome({required this.numeral, required this.title});

  final String numeral;
  final String title;
}

abstract final class MinorArcanaArt {
  MinorArcanaArt._();

  static const root = 'lib/assets/images/tarot/minor_arcana';

  static const suits = <String>['wands', 'cups', 'swords', 'pentacles'];

  static const suitTitles = <String, String>{
    'wands': 'DEĞNEKLER',
    'cups': 'KUPALAR',
    'swords': 'KILIÇLAR',
    'pentacles': 'TILSIMLAR',
  };

  /// Rank index 1–14 → file stem + top numeral.
  static const rankStems = <String>[
    '01_ace',
    '02_two',
    '03_three',
    '04_four',
    '05_five',
    '06_six',
    '07_seven',
    '08_eight',
    '09_nine',
    '10_ten',
    '11_page',
    '12_knight',
    '14_queen',
    '13_king',
  ];

  static const rankNumerals = <String>[
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'P',
    'Ş',
    'KÇ',
    'KR',
  ];

  static String fileFor(String suit, int number) {
    final i = number.clamp(1, 14) - 1;
    return '${rankStems[i]}_$suit.webp';
  }

  static String assetFor(String suit, int number) =>
      '$root/$suit/${fileFor(suit, number)}';

  static List<String> get allAssets => [
        for (final suit in suits)
          for (var n = 1; n <= 14; n++) assetFor(suit, n),
      ];

  static bool isMinorAsset(String path) =>
      path.contains('tarot/minor_arcana/') ||
      path.contains('cards/tarot/cups/') ||
      path.contains('cards/tarot/wands/') ||
      path.contains('cards/tarot/swords/') ||
      path.contains('cards/tarot/pentacles/');

  static MinorChrome? chromeFor(String path) {
    final parsed = parse(path);
    if (parsed == null) return null;
    return MinorChrome(
      numeral: rankNumerals[parsed.number - 1],
      title: suitTitles[parsed.suit]!,
    );
  }

  static ({String suit, int number})? parse(String path) {
    final name = path.split('/').last.toLowerCase();
    // The runtime typically uses `.webp`, but some widgets/tests still pass `.png`.
    final normalized = name.replaceAll('.png', '.webp');
    for (final suit in suits) {
      for (var n = 1; n <= 14; n++) {
        if (normalized == fileFor(suit, n).toLowerCase()) {
          return (suit: suit, number: n);
        }
      }
    }
    return null;
  }
}
