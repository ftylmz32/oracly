/// Marks journal rows saved via favorites or tarot memory.
library;

import '../../favorite_moments/models/favorite_moment.dart';
import '../models/discovery_journal_entry.dart';

abstract final class DiscoveryJournalSaved {
  DiscoveryJournalSaved._();

  static List<DiscoveryJournalEntry> mark(
    List<DiscoveryJournalEntry> items,
    List<FavoriteMoment> favorites,
  ) {
    if (items.isEmpty || favorites.isEmpty) return items;
    final keys = <String>{};
    for (final f in favorites) {
      keys.add('${f.source.journalKind.name}:${f.sourceRef}');
      keys.add(f.sourceRef);
      keys.add(f.id);
      // Daily favorites use dateKey; journal rows use daily_$dateKey.
      if (f.source == FavoriteMomentSource.dailyMessage) {
        keys.add('daily_${f.sourceRef}');
        keys.add('${f.source.journalKind.name}:daily_${f.sourceRef}');
      }
    }
    return [
      for (final item in items)
        if (item.isSaved ||
            keys.contains('${item.kind.name}:${item.id}') ||
            keys.contains(item.id))
          item.isSaved
              ? item
              : item.copyWith(isSaved: true)
        else
          item,
    ];
  }
}
