/// Closed suffix tables for aspect and house words (TR / EN / RU).
///
/// Each list names only the inflections a genuine aspect / house word takes,
/// so a token can never continue into an unrelated longer word: `trin`
/// never reaches `тринадцать`, `ev` never reaches `evre` / `evren` / `evet`,
/// `kare` never reaches `kareli`.
library;

abstract final class YildiznameLexicalSuffixes {
  YildiznameLexicalSuffixes._();

  /// Turkish case / possessive / derivational suffixes plus the English
  /// plural. Up to two may chain (`kare-si-nde`, `karşıt-lığı-nda`).
  static const aspectLatin = [
    's',
    'ı', 'i', 'u', 'ü',
    'ın', 'in', 'un', 'ün',
    'a', 'e', 'ya', 'ye', 'yı', 'yi', 'yu', 'yü',
    'da', 'de', 'ta', 'te', 'dan', 'den', 'tan', 'ten',
    'nda', 'nde', 'ndan', 'nden', 'nın', 'nin', 'nun', 'nün',
    'daki', 'deki', 'ndaki', 'ndeki',
    'sı', 'si', 'su', 'sü',
    'lar', 'ler',
    'lık', 'lik', 'luk', 'lük', 'lığı', 'liği', 'luğu', 'lüğü',
  ];

  /// Russian noun and adjective endings after an aspect stem
  /// (`квадрат-е`, `соединен-ие`, `оппозиц-ия`, `секстил-ь`, `квадрат-ный`).
  static const aspectCyrillic = [
    'иями', 'иях', 'ием', 'ией', 'ие', 'ия', 'ии', 'ию',
    'ный', 'ная', 'ное', 'ного', 'ном', 'ной', 'ные', 'ных', 'ным',
    'ом', 'ем', 'ой', 'ей', 'ах', 'ях', 'ам', 'ям', 'ов', 'ев',
    'а', 'у', 'ы', 'е', 'и', 'я', 'ю', 'о',
  ];

  /// Turkish `ev` (house) inflections: `evde`, `evindeki`, `evlerinde`.
  static const houseEv = [
    'i', 'e', 'in', 'de', 'den', 'deki', 'dedir',
    'inde', 'indeki', 'ine', 'inden', 'indedir', 'idir',
    'ler', 'leri', 'lerde', 'lerin', 'lerinde', 'lerdeki',
  ];
}
