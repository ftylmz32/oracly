/// Clips insight text for favorite moment cards.

library;



abstract final class FavoriteMomentText {

  FavoriteMomentText._();



  static String clip(String raw, {int max = 140}) {

    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.isEmpty) return text;

    if (text.length <= max) return text;

    final cut = text.substring(0, max);

    final last = cut.lastIndexOf(' ');

    final base = last > max ~/ 2 ? cut.substring(0, last) : cut;

    return '$base…';

  }



  static String firstNonEmpty(Iterable<String> values) {

    for (final value in values) {

      final trimmed = value.trim();

      if (trimmed.isNotEmpty) return clip(trimmed);

    }

    return '';

  }

}


