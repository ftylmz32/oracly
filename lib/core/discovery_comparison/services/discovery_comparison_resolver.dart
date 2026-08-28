/// Loads full comparison snapshots from persisted records.
library;

import '../../../core/domain/models/astrology_record.dart';
import '../../../core/domain/models/conversation_record.dart';
import '../../../core/domain/models/reading.dart';
import '../../../features/daily_message/data/daily_return_store.dart';
import '../../../features/daily_message/models/daily_message.dart';
import '../../../features/discovery_journal/models/discovery_journal_entry.dart';
import '../../../features/tarot/history/tarot_history_privacy.dart';
import '../models/discovery_comparison_kind.dart';
import '../models/discovery_comparison_snapshot.dart';

abstract final class DiscoveryComparisonResolver {
  DiscoveryComparisonResolver._();

  static DiscoveryComparisonSnapshot? snapshotFromEntry(
    DiscoveryJournalEntry entry, {
    ReadingModel? reading,
    DailyMessage? daily,
    AstrologyRecord? astrology,
    ConversationRecord? conversation,
  }) {
    final kind = DiscoveryComparisonKind.fromJournalKind(entry.kind);
    if (kind == null) return null;

    final text = switch (kind) {
      DiscoveryComparisonKind.tarot when reading != null =>
        _tarotText(reading),
      DiscoveryComparisonKind.dailyMessage when daily != null => daily.text,
      DiscoveryComparisonKind.astrology when astrology != null =>
        astrology.horoscope,
      DiscoveryComparisonKind.companion when conversation != null =>
        _companionText(conversation),
      DiscoveryComparisonKind.starMap => entry.preview,
      _ => entry.preview,
    };

    if (text.trim().isEmpty) return null;
    return DiscoveryComparisonSnapshot(
      id: entry.id,
      date: entry.date,
      title: entry.title,
      preview: entry.preview,
      text: text,
    );
  }

  static DailyMessage? dailyById(DailyReturnStore store, String entryId) {
    if (!entryId.startsWith('daily_')) return null;
    final key = entryId.substring('daily_'.length);
    final today = store.readToday(DateTime.now());
    if (today?.dateKey == key) return today;
    final previous = store.readPrevious(DateTime.now());
    if (previous?.dateKey == key) return previous;
    return null;
  }

  static String _tarotText(ReadingModel reading) {
    final parts = <String>[
      TarotHistoryPrivacy.shortInsight(reading),
      if (reading.cardName.isNotEmpty) reading.cardName,
      for (final card in reading.cards) card.cardName,
    ];
    return parts.join(' ');
  }

  static String _companionText(ConversationRecord record) {
    final assistant = <String>[];
    for (final raw in record.messagesJson) {
      if ('${raw['role']}' != 'assistant') continue;
      final content = '${raw['content']}'.trim();
      if (content.isNotEmpty) assistant.add(content);
    }
    if (assistant.isEmpty) return record.title.trim();
    return assistant.last;
  }
}
