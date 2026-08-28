/// Text extraction + dated window for discovery profile (scale-aware).
library;

import '../../../core/domain/models/astrology_record.dart';
import '../../../core/domain/models/birth_chart_record.dart';
import '../../../core/domain/models/conversation_record.dart';
import '../../../core/domain/models/dream_record.dart';
import '../../../core/domain/models/reading.dart';
import '../../../core/history/history_scale_policy.dart';
import '../../birth_chart/data/birth_chart_record_mapper.dart';
import '../../daily_message/models/daily_message.dart';
import '../models/dated_discovery_text.dart';
import '../models/personal_discovery_sources.dart';

abstract final class PersonalDiscoveryProfileTexts {
  PersonalDiscoveryProfileTexts._();

  static List<DatedDiscoveryText> dated(PersonalDiscoverySources sources) {
    final items = <DatedDiscoveryText>[
      for (final r in sources.readings)
        DatedDiscoveryText(source: 'tarot', text: tarot(r), at: r.createdAt),
      for (final d in sources.dreams)
        DatedDiscoveryText(
          source: 'dream',
          text: dream(d),
          at: d.updatedAt ?? d.createdAt,
        ),
      for (final c in sources.coffee)
        DatedDiscoveryText(source: 'coffee', text: c.fullText, at: c.createdAt),
      for (final c in sources.conversations)
        if (c.messagesJson.isNotEmpty)
          DatedDiscoveryText(
            source: 'reflection',
            text: conversation(c),
            at: c.updatedAt,
          ),
      for (final p in sources.palm)
        DatedDiscoveryText(
          source: 'palm',
          text: '${p.fullText} ${p.themes.join(' ')}',
          at: p.createdAt,
        ),
      for (final a in sources.astrology)
        DatedDiscoveryText(
          source: 'astrology',
          text: astrology(a),
          at: a.date,
        ),
      if (sources.starChart != null)
        DatedDiscoveryText(
          source: 'starMap',
          text: starMap(sources.starChart!),
          at: sources.starChart!.updatedAt ?? sources.starChart!.createdAt,
        ),
      for (final d in sources.dailyMessages)
        DatedDiscoveryText(
          source: 'daily',
          text: daily(d),
          at: d.day,
        ),
    ];
    return HistoryScalePolicy.newestByDate(items, (e) => e.at);
  }

  static DateTime? latest(PersonalDiscoverySources sources) {
    final stamps = <DateTime>[
      ...sources.readings.map((r) => r.createdAt),
      ...sources.dreams.map((d) => d.updatedAt ?? d.createdAt),
      ...sources.coffee.map((c) => c.createdAt),
      ...sources.conversations.map((c) => c.updatedAt),
      ...sources.palm.map((p) => p.createdAt),
      ...sources.astrology.map((a) => a.date),
      ...sources.dailyMessages.map((d) => d.day),
      if (sources.starChart != null)
        sources.starChart!.updatedAt ?? sources.starChart!.createdAt,
    ];
    if (stamps.isEmpty) return null;
    stamps.sort();
    return stamps.last;
  }

  static String tarot(ReadingModel reading) {
    final insight = reading.summaryExcerpt?.trim();
    final short = (insight != null && insight.isNotEmpty)
        ? insight
        : _clip(reading.aiSummary, 140);
    final cards = [
      reading.cardName,
      ...reading.cards.map((c) => c.cardName),
    ].join(' ');
    return '$short $cards ${reading.spreadType} '
        '${reading.journal.emotionalKeywords.join(' ')} '
        '${reading.journal.tags.join(' ')}';
  }

  static String dream(DreamRecord dream) =>
      '${dream.text} ${dream.analysis} ${dream.tags.join(' ')}';

  static String conversation(ConversationRecord record) => record.messagesJson
      .map((m) => '${m['text'] ?? m['content'] ?? ''}')
      .join(' ');

  static String astrology(AstrologyRecord record) =>
      '${record.sign} ${record.horoscope}';

  static String starMap(BirthChartRecord record) {
    try {
      final chart = BirthChartRecordMapper.fromRecord(record);
      final themes =
          chart.lifeThemes.map((t) => '${t.title} ${t.body}').join(' ');
      final insights =
          chart.insights.map((i) => '${i.title} ${i.body}').join(' ');
      return '${chart.sun.sign.labelTr} $themes $insights';
    } catch (_) {
      return '';
    }
  }

  static String daily(DailyMessage message) =>
      '${message.theme ?? ''} ${message.text} ${message.sunSign ?? ''}';

  static String _clip(String raw, int max) {
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= max) return text;
    return '${text.substring(0, max).trim()}…';
  }
}
