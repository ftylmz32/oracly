library;

const int coffeeV2IntentionMaxLength = 200;

enum CoffeeV2IntentionChoice { general, love, career, money, person, other }

extension CoffeeV2IntentionChoiceValue on CoffeeV2IntentionChoice {
  String get label => switch (this) {
    CoffeeV2IntentionChoice.general => 'Genel',
    CoffeeV2IntentionChoice.love => 'Aşk / İlişkiler',
    CoffeeV2IntentionChoice.career => 'İş / Kariyer',
    CoffeeV2IntentionChoice.money => 'Para',
    CoffeeV2IntentionChoice.person => 'Aklımdaki kişi',
    CoffeeV2IntentionChoice.other => 'Diğer',
  };

  String? get intention => switch (this) {
    CoffeeV2IntentionChoice.general => 'Önümüzdeki dönem genel olarak',
    CoffeeV2IntentionChoice.love => 'Aşk ve ilişkilerim hakkında',
    CoffeeV2IntentionChoice.career => 'İşim ve kariyerim hakkında',
    CoffeeV2IntentionChoice.money => 'Maddi durumum hakkında',
    CoffeeV2IntentionChoice.person => 'Aklımdaki kişiyle ilgili',
    CoffeeV2IntentionChoice.other => null,
  };
}

String? canonicalCoffeeV2Intention(String? value) {
  final normalized = value?.trim();
  if (normalized == null ||
      normalized.isEmpty ||
      normalized.length > coffeeV2IntentionMaxLength ||
      RegExp(r'[\x00-\x1F\x7F-\x9F]').hasMatch(normalized) ||
      RegExp(r'<[^>]*>|[<>]').hasMatch(normalized)) {
    return null;
  }
  return normalized;
}
