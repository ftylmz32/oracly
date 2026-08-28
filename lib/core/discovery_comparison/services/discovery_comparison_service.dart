/// Resolves and compares two journal discoveries from real stores.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/domain/models/astrology_record.dart';
import '../../../core/domain/models/conversation_record.dart';
import '../../../core/domain/models/reading.dart';
import '../../../features/daily_message/data/daily_return_store.dart';
import '../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../../../features/discovery_journal/models/discovery_journal_kind.dart';
import '../models/discovery_comparison_kind.dart';
import '../models/discovery_comparison_result.dart';
import '../models/discovery_comparison_snapshot.dart';
import 'discovery_comparison_engine.dart';
import 'discovery_comparison_pair_finder.dart';
import 'discovery_comparison_resolver.dart';

abstract final class DiscoveryComparisonService {
  DiscoveryComparisonService._();

  static Future<DiscoveryComparisonResult?> compareEntries(
    WidgetRef ref, {
    required DiscoveryJournalEntry later,
    required DiscoveryJournalEntry earlier,
  }) async {
    final kind = DiscoveryComparisonKind.fromJournalKind(later.kind);
    if (kind == null || earlier.kind != later.kind) return null;

    final store = DailyReturnStore(ref.read(localStorageProvider));
    Future<ReadingModel?> readingFor(String id) async {
      final readings = await ref.read(historyServiceProvider).getAll();
      for (final reading in readings) {
        if (reading.id == id || reading.sessionId == id) return reading;
      }
      return null;
    }

    final earlierSnap = await _snapshot(
      ref,
      earlier,
      store: store,
      readingLoader: readingFor,
    );
    final laterSnap = await _snapshot(
      ref,
      later,
      store: store,
      readingLoader: readingFor,
    );
    if (earlierSnap == null || laterSnap == null) return null;
    return DiscoveryComparisonEngine.compare(
      kind: kind,
      earlier: earlierSnap,
      later: laterSnap,
    );
  }

  static Future<DiscoveryComparisonResult?> compareWithPrior(
    WidgetRef ref, {
    required List<DiscoveryJournalEntry> items,
    required DiscoveryJournalEntry current,
  }) async {
    final prior = DiscoveryComparisonPairFinder.priorEntry(items, current);
    if (prior == null) return null;
    return compareEntries(ref, earlier: prior, later: current);
  }

  static Future<DiscoveryComparisonSnapshot?> _snapshot(
    WidgetRef ref,
    DiscoveryJournalEntry entry, {
    required DailyReturnStore store,
    required Future<ReadingModel?> Function(String id) readingLoader,
  }) async {
    switch (entry.kind) {
      case DiscoveryJournalKind.tarot:
        final reading = await readingLoader(entry.id);
        return DiscoveryComparisonResolver.snapshotFromEntry(
          entry,
          reading: reading,
        );
      case DiscoveryJournalKind.dailyMessage:
        return DiscoveryComparisonResolver.snapshotFromEntry(
          entry,
          daily: DiscoveryComparisonResolver.dailyById(store, entry.id),
        );
      case DiscoveryJournalKind.astrology:
        final records = await ref.read(astrologyRepositoryProvider).getHistory();
        AstrologyRecord? match;
        for (final record in records) {
          if (record.id == entry.id) {
            match = record;
            break;
          }
        }
        return DiscoveryComparisonResolver.snapshotFromEntry(
          entry,
          astrology: match,
        );
      case DiscoveryJournalKind.companion:
        final conversations =
            await ref.read(aiConversationRepositoryProvider).getAll();
        ConversationRecord? match;
        for (final record in conversations) {
          if (record.id == entry.id) {
            match = record;
            break;
          }
        }
        return DiscoveryComparisonResolver.snapshotFromEntry(
          entry,
          conversation: match,
        );
      case DiscoveryJournalKind.starMap:
        return DiscoveryComparisonResolver.snapshotFromEntry(entry);
      default:
        return null;
    }
  }
}
