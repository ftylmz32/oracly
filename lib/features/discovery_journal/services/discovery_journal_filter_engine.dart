/// Pure local filter over persisted journal rows.
library;

import '../models/discovery_journal_entry.dart';
import '../models/discovery_journal_filter_options.dart';
import '../models/discovery_journal_kind.dart';
import '../models/discovery_journal_query.dart';
import '../models/discovery_journal_range.dart';
import 'discovery_journal_aggregator.dart';

abstract final class DiscoveryJournalFilterEngine {
  DiscoveryJournalFilterEngine._();

  static List<DiscoveryJournalEntry> apply(
    List<DiscoveryJournalEntry> items,
    DiscoveryJournalQuery query, {
    DateTime? now,
  }) {
    var out = DiscoveryJournalAggregator.inRange(
      items,
      query.range,
      now: now,
    );
    final kind = query.kind;
    if (kind != null) {
      out = [for (final e in out) if (e.kind == kind) e];
    }
    if (query.savedOnly) {
      out = [for (final e in out) if (e.isSaved) e];
    }
    final theme = query.theme?.trim().toLowerCase();
    if (theme != null && theme.isNotEmpty) {
      out = [
        for (final e in out)
          if (e.themes.any((t) => t.toLowerCase() == theme)) e,
      ];
    }
    return out;
  }

  static DiscoveryJournalFilterOptions options(
    List<DiscoveryJournalEntry> items, {
    DateTime? now,
  }) {
    if (items.isEmpty) return const DiscoveryJournalFilterOptions();
    final clock = now ?? DateTime.now();
    return DiscoveryJournalFilterOptions(
      ranges: _ranges(items, clock),
      kinds: _kinds(items),
      themes: _themes(items),
      hasSaved: items.any((e) => e.isSaved),
    );
  }

  static List<DiscoveryJournalRange> _ranges(
    List<DiscoveryJournalEntry> items,
    DateTime now,
  ) {
    final out = <DiscoveryJournalRange>[];
    for (final range in const [
      DiscoveryJournalRange.last7,
      DiscoveryJournalRange.last30,
      DiscoveryJournalRange.last90,
    ]) {
      final filtered = DiscoveryJournalAggregator.inRange(
        items,
        range,
        now: now,
      );
      if (filtered.isEmpty) continue;
      if (filtered.length == items.length) continue;
      out.add(range);
    }
    out.add(DiscoveryJournalRange.all);
    return out;
  }

  static List<DiscoveryJournalKind> _kinds(List<DiscoveryJournalEntry> items) {
    final seen = <DiscoveryJournalKind>{};
    final ordered = <DiscoveryJournalKind>[];
    for (final item in items) {
      if (seen.add(item.kind)) ordered.add(item.kind);
    }
    return ordered;
  }

  static List<String> _themes(List<DiscoveryJournalEntry> items) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final theme in item.themes) {
        final key = theme.trim();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        if (byCount != 0) return byCount;
        return a.compareTo(b);
      });
    return keys.take(8).toList(growable: false);
  }
}
