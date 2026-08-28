/// Maps persisted feature records into journal rows. Never invents.
library;

import '../../../core/domain/models/astrology_record.dart';
import '../../../core/domain/models/birth_chart_record.dart';
import '../../../core/domain/models/conversation_record.dart';
import '../../../core/domain/models/dream_record.dart';
import '../../../core/domain/models/reading.dart';
import '../../birth_chart/data/birth_chart_record_mapper.dart';
import '../../coffee/models/coffee_reading.dart';
import '../../daily_message/models/daily_message.dart';
import '../../palm/models/palm_reading.dart';
import '../../personal_discovery/services/personal_theme_extractor.dart';
import '../../tarot/history/tarot_history_privacy.dart';
import '../copy/discovery_journal_copy.dart';
import '../models/discovery_journal_entry.dart';
import '../models/discovery_journal_kind.dart';

abstract final class DiscoveryJournalMap {
  DiscoveryJournalMap._();

  static DiscoveryJournalEntry reading(ReadingModel reading) {
    final preview = _clip(TarotHistoryPrivacy.shortInsight(reading), '');
    return DiscoveryJournalEntry(
      id: reading.id,
      kind: DiscoveryJournalKind.tarot,
      date: reading.createdAt,
      title: TarotHistoryPrivacy.spreadTitle(reading.spreadType),
      preview: preview,
      // Themes from clipped fields only — never full AI body at scale.
      themes: _themes([
        preview,
        reading.intention ?? '',
        reading.cardName,
      ]),
      isSaved: reading.isFavorite,
    );
  }

  static DiscoveryJournalEntry dream(DreamRecord dream) {
    return DiscoveryJournalEntry(
      id: dream.id,
      kind: DiscoveryJournalKind.dream,
      date: dream.createdAt,
      title: _clip(dream.text, DiscoveryJournalCopy.dreamFallback),
      preview: _clip(dream.analysis, ''),
      themes: _themes([dream.text, dream.analysis]),
    );
  }

  static DiscoveryJournalEntry coffee(CoffeeReading reading) {
    return DiscoveryJournalEntry(
      id: reading.id,
      kind: DiscoveryJournalKind.coffee,
      date: reading.createdAt,
      title: _clip(reading.overall, DiscoveryJournalCopy.coffeeFallback),
      preview: _clip(reading.takeaway, ''),
      themes: _themes([
        reading.overall,
        reading.love,
        reading.career,
        reading.takeaway,
      ]),
    );
  }

  static DiscoveryJournalEntry palm(PalmReading reading) {
    return DiscoveryJournalEntry(
      id: reading.id,
      kind: DiscoveryJournalKind.palm,
      date: reading.createdAt,
      title: _clip(reading.overall, DiscoveryJournalCopy.palmFallback),
      preview: _clip(reading.themes.join(' · '), ''),
      themes: _themes([reading.overall, ...reading.themes]),
    );
  }

  static DiscoveryJournalEntry conversation(ConversationRecord record) {
    return DiscoveryJournalEntry(
      id: record.id,
      kind: DiscoveryJournalKind.companion,
      date: record.updatedAt,
      title: DiscoveryJournalCopy.companionTitle,
      preview: _clip(record.title, ''),
      themes: _themes([record.title]),
    );
  }

  static DiscoveryJournalEntry astrology(AstrologyRecord record) {
    return DiscoveryJournalEntry(
      id: record.id,
      kind: DiscoveryJournalKind.astrology,
      date: record.date,
      title: record.sign.trim().isEmpty
          ? DiscoveryJournalCopy.astroFallback
          : record.sign.trim(),
      preview: _clip(record.horoscope, ''),
      themes: _themes([record.horoscope, record.sign]),
    );
  }

  static DiscoveryJournalEntry starMap(BirthChartRecord record) {
    String preview = '';
    try {
      final chart = BirthChartRecordMapper.fromRecord(record);
      preview = chart.sun.sign.labelTr;
    } catch (_) {}
    return DiscoveryJournalEntry(
      id: record.id,
      kind: DiscoveryJournalKind.starMap,
      date: record.updatedAt ?? record.createdAt,
      title: DiscoveryJournalCopy.starTitle,
      preview: preview,
      themes: _themes([preview]),
    );
  }

  static DiscoveryJournalEntry daily(DailyMessage message) {
    return DiscoveryJournalEntry(
      id: 'daily_${message.dateKey}',
      kind: DiscoveryJournalKind.dailyMessage,
      date: message.day,
      title: message.theme?.trim().isNotEmpty == true
          ? message.theme!.trim()
          : DiscoveryJournalCopy.dailyFallback,
      preview: _clip(message.text, ''),
      themes: _themes([message.text, message.theme ?? '']),
    );
  }

  static List<String> _themes(Iterable<String> texts) {
    final found = <String>{};
    for (final raw in texts) {
      for (final theme in PersonalThemeExtractor.themesIn(raw)) {
        found.add(theme.label);
      }
    }
    return found.toList(growable: false);
  }

  static String _clip(String raw, String fallback) {
    final text = raw.trim();
    if (text.isEmpty) return fallback;
    if (text.length <= 72) return text;
    return '${text.substring(0, 72).trim()}…';
  }
}
