/// Merges existing persisted records. Never invents history.
library;

import '../../../core/domain/models/astrology_record.dart';
import '../../../core/domain/models/birth_chart_record.dart';
import '../../../core/domain/models/conversation_record.dart';
import '../../../core/domain/models/dream_record.dart';
import '../../../core/domain/models/reading.dart';
import '../../coffee/models/coffee_reading.dart';
import '../../daily_message/models/daily_message.dart';
import '../../palm/models/palm_reading.dart';
import '../models/discovery_journal_entry.dart';
import '../models/discovery_journal_range.dart';
import 'discovery_journal_map.dart';

abstract final class DiscoveryJournalAggregator {
  DiscoveryJournalAggregator._();

  static List<DiscoveryJournalEntry> merge({
    List<ReadingModel> readings = const [],
    List<DreamRecord> dreams = const [],
    List<CoffeeReading> coffee = const [],
    List<ConversationRecord> conversations = const [],
    List<PalmReading> palm = const [],
    List<AstrologyRecord> astrology = const [],
    BirthChartRecord? starChart,
    List<DailyMessage> daily = const [],
  }) {
    final items = <DiscoveryJournalEntry>[
      ...readings.map(DiscoveryJournalMap.reading),
      ...dreams.map(DiscoveryJournalMap.dream),
      ...coffee.map(DiscoveryJournalMap.coffee),
      ...conversations.where(_hasMessages).map(DiscoveryJournalMap.conversation),
      ...palm.map(DiscoveryJournalMap.palm),
      ...astrology.map(DiscoveryJournalMap.astrology),
      if (starChart != null) DiscoveryJournalMap.starMap(starChart),
      ...daily.map(DiscoveryJournalMap.daily),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static List<DiscoveryJournalEntry> inRange(
    List<DiscoveryJournalEntry> items,
    DiscoveryJournalRange range, {
    DateTime? now,
  }) {
    final start = range.startOf(now ?? DateTime.now());
    if (start == null) return items;
    return [
      for (final item in items)
        if (!item.date.isBefore(start)) item,
    ];
  }

  static bool _hasMessages(ConversationRecord record) =>
      record.messagesJson.isNotEmpty;
}
