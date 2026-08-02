import '../models/tarot_card.dart';

class TarotHelpers {
  TarotHelpers._();

  static String formatIntention(String intention) {
    final trimmed = intention.trim();
    return trimmed.isEmpty ? 'Belirtilmedi' : trimmed;
  }

  static String spreadLabel(int cardCount) {
    switch (cardCount) {
      case 1:
        return 'Tek kart';
      case 3:
        return 'Üç kart (Geçmiş · Şimdi · Gelecek)';
      case 10:
        return 'On kartlık derin açılım';
      default:
        return '$cardCount kart';
    }
  }

  static String formatCard(
    TarotCard card, {
    required int position,
  }) {
    final buffer = StringBuffer()
      ..writeln('Kart $position: ${card.name}')
      ..writeln('- Özet: ${card.summary}')
      ..writeln('- Anlam: ${card.meaning}')
      ..writeln(
        '- Anahtar kelimeler: ${card.keywords.join(", ")}',
      );

    if (card.element != null) {
      buffer.writeln('- Element: ${card.element}');
    }

    return buffer.toString().trim();
  }

  static String formatSpreadContext(
    List<TarotCard> cards,
    String intention,
  ) {
    final buffer = StringBuffer()
      ..writeln('Açılım: ${spreadLabel(cards.length)}')
      ..writeln('Niyet: ${formatIntention(intention)}')
      ..writeln();

    for (var i = 0; i < cards.length; i++) {
      buffer.writeln(
        formatCard(
          cards[i],
          position: i + 1,
        ),
      );

      if (i < cards.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
