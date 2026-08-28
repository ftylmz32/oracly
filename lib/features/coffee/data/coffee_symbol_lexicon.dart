/// Traditional coffee-cup senses — used only when the provider named the symbol.
library;

import '../../../core/l10n/l10n.dart';

enum CoffeeSymbolDomain { general, love, work, near }

class CoffeeSymbolSense {
  const CoffeeSymbolSense({required this.id, required this.aliases});

  final String id;
  final List<String> aliases;

  String get meaning => OraclyL10n.t('coffee.sym.$id.g');
  String get work => OraclyL10n.t('coffee.sym.$id.w');
  String get love => OraclyL10n.t('coffee.sym.$id.l');
  String get near => OraclyL10n.t('coffee.sym.$id.n');

  String forDomain(CoffeeSymbolDomain domain) => switch (domain) {
        CoffeeSymbolDomain.love => love,
        CoffeeSymbolDomain.work => work,
        CoffeeSymbolDomain.near => near,
        CoffeeSymbolDomain.general => meaning,
      };
}

abstract final class CoffeeSymbolLexicon {
  CoffeeSymbolLexicon._();

  static CoffeeSymbolSense? match(String name) {
    final n = _norm(name);
    if (n.isEmpty) return null;
    for (final sense in all) {
      for (final alias in sense.aliases) {
        if (n.contains(alias) || alias.contains(n)) return sense;
      }
    }
    return null;
  }

  static List<CoffeeSymbolSense> presentIn({
    required Iterable<String> names,
  }) {
    final seen = <String>{};
    final out = <CoffeeSymbolSense>[];
    for (final name in names) {
      final sense = match(name);
      if (sense == null || !seen.add(sense.id)) continue;
      out.add(sense);
    }
    return out;
  }

  static const all = <CoffeeSymbolSense>[
    CoffeeSymbolSense(id: 'road', aliases: ['yol', 'road', 'path', 'sokak', 'açık yol']),
    CoffeeSymbolSense(id: 'bird', aliases: ['kuş', 'bird', 'uçan']),
    CoffeeSymbolSense(id: 'heart', aliases: ['kalp', 'heart', 'yürek']),
    CoffeeSymbolSense(id: 'ring', aliases: ['yüzük', 'ring', 'halka']),
    CoffeeSymbolSense(id: 'eye', aliases: ['göz', 'eye']),
    CoffeeSymbolSense(id: 'mountain', aliases: ['dağ', 'mountain']),
    CoffeeSymbolSense(id: 'key', aliases: ['anahtar', 'key']),
    CoffeeSymbolSense(id: 'star', aliases: ['yıldız', 'star']),
    CoffeeSymbolSense(id: 'tree', aliases: ['ağaç', 'tree']),
    CoffeeSymbolSense(
      id: 'person',
      aliases: ['insan', 'kişi', 'silüet', 'figure', 'person'],
    ),
    CoffeeSymbolSense(
      id: 'letter',
      aliases: ['mektup', 'yazı', 'letter', 'kâğıt', 'kagit', 'kağıt'],
    ),
  ];

  static String _norm(String name) =>
      name.toLowerCase().trim().replaceAll('â', 'a');
}
