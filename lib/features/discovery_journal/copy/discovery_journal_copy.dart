/// Keşif Günlüğü — honest archive copy. No invented history.
library;

import '../../../core/l10n/l10n.dart';
import '../../personal_discovery/models/cross_discovery_insight.dart';
import '../../personal_discovery/models/discovery_theme.dart';
import '../models/discovery_journal_kind.dart';
import '../models/discovery_journal_range.dart';
import 'discovery_journal_filter_copy.dart';

abstract final class DiscoveryJournalCopy {
  DiscoveryJournalCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('journal.screen_title');
  static String get emptyTitle => _t('journal.empty_title');
  static String get emptyMessage => _t('journal.empty');
  static String get subtitle => _t('journal.subtitle');
  static String get storyNone => _t('journal.story_none');
  static String get philosophy => _t('journal.philosophy');
  static String get nextCoffee => _t('journal.next_coffee');
  static String get nextPalm => _t('journal.next_palm');
  static String get nextOr => _t('journal.next_or');
  static String get soulMateNote => _t('journal.soulmate_note');
  static String get themeSummaryTitle => _t('journal.cross_title');
  static String get openCta => _t('journal.open');
  static String get badgeTarot => _t('journal.badge.tarot');
  static String get badgeDream => _t('journal.badge.dream');
  static String get badgeCoffee => _t('journal.badge.coffee');
  static String get badgeCompanion => _t('journal.badge.or');
  static String get badgePalm => _t('journal.badge.palm');
  static String get companionTitle => _t('journal.companion_title');
  static String get coffeeFallback => _t('journal.coffee_fb');
  static String get dreamFallback => _t('journal.dream_fb');
  static String get palmFallback => _t('journal.palm_fb');
  static String get astroFallback => _t('journal.astro_fb');
  static String get dailyFallback => _t('journal.daily_fb');
  static String get starTitle => _t('journal.star_title');
  static String get filter7 => _t('journal.filter_7');
  static String get filter30 => _t('journal.filter_30');
  static String get filter90 => _t('journal.filter_90');
  static String get filterAll => _t('journal.filter_all');
  static String get filterEmpty => _t('journal.filter_empty');
  static String get filterSaved => _t('journal.filter_saved');
  static String get archiveTitle => _t('journal.archive_title');
  static String get crossTitle => _t('journal.cross_title');
  static String get observationTitle => _t('profile.observation_title');

  static String areas(int n) => _t('journal.areas').replaceAll('{n}', '$n');

  static String discoveries(int n) =>
      '$n ${_t('journal.discoveries').replaceAll('{n}', '$n')}';

  static String lastDays(int days) =>
      _t('journal.last_days').replaceAll('{n}', '$days');

  static String filterLabel(DiscoveryJournalRange range) =>
      DiscoveryJournalFilterCopy.range(range);

  static String sourceLabel(String raw) => switch (raw) {
        'tarot' => _t('journal.src.tarot'),
        'dream' => _t('journal.src.dream'),
        'coffee' => _t('journal.src.coffee'),
        'reflection' => _t('journal.src.reflection'),
        'palm' => _t('journal.src.palm'),
        'astrology' => _t('journal.src.astrology'),
        'star' || 'starMap' || 'star_map' => _t('journal.src.star'),
        'daily' || 'dailyMessage' => _t('journal.src.daily'),
        _ => raw,
      };

  static String sourcesLine(List<String> sources) =>
      sources.map(sourceLabel).join(' · ');

  static String badge(DiscoveryJournalKind kind) => switch (kind) {
        DiscoveryJournalKind.tarot => badgeTarot,
        DiscoveryJournalKind.dream => badgeDream,
        DiscoveryJournalKind.coffee => badgeCoffee,
        DiscoveryJournalKind.companion => badgeCompanion,
        DiscoveryJournalKind.palm => badgePalm,
        DiscoveryJournalKind.astrology => _t('journal.badge.astro'),
        DiscoveryJournalKind.starMap => _t('journal.badge.star'),
        DiscoveryJournalKind.dailyMessage => _t('journal.badge.daily'),
      };

  static String recency(String band) => switch (band) {
        'recent' => _t('journal.recency_recent'),
        'aging' => _t('journal.recency_aging'),
        _ => _t('journal.recency_distant'),
      };

  static String heroTheme(String raw) {
    final label = DiscoveryTheme.resolve(raw)?.localized ?? raw.trim();
    return label.split('').map((c) {
      if (c == 'i' || c == 'İ') return 'İ';
      if (c == 'ı') return 'I';
      return c.toUpperCase();
    }).join();
  }

  static String insight(CrossDiscoveryInsight item, {DateTime? now}) {
    final n = item.discoveryCount < 2 ? item.sourceCount : item.discoveryCount;
    if (n < 2) return '';
    final day = now ?? DateTime.now();
    final recent = day.difference(item.lastObserved) <= const Duration(days: 30);
    final key = recent ? 'journal.insight_30' : 'journal.insight';
    final raw = DiscoveryTheme.resolve(item.theme)?.localized ?? item.theme;
    return _t(key).replaceAll('{theme}', _title(raw)).replaceAll('{n}', '$n');
  }

  static String _title(String raw) {
    final label = raw.trim();
    if (label.isEmpty) return label;
    final first = label.substring(0, 1);
    final upper = switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
    return '$upper${label.substring(1)}';
  }

  static String story(List<String> themes) {
    final clean = [
      for (final raw in themes)
        if (raw.trim().isNotEmpty)
          DiscoveryTheme.resolve(raw)?.localized ?? raw.trim(),
    ].take(4).toList();
    if (clean.isEmpty) return storyNone;
    if (clean.length == 1) {
      return _t('journal.story1').replaceAll('{a}', clean.first);
    }
    if (clean.length == 2) {
      return _t('journal.story2')
          .replaceAll('{a}', clean[0])
          .replaceAll('{b}', clean[1]);
    }
    if (clean.length == 3) {
      return _t('journal.story3')
          .replaceAll('{a}', clean[0])
          .replaceAll('{b}', clean[1])
          .replaceAll('{c}', clean[2]);
    }
    return _t('journal.story4')
        .replaceAll('{a}', clean[0])
        .replaceAll('{b}', clean[1])
        .replaceAll('{c}', clean[2])
        .replaceAll('{d}', clean[3]);
  }
}
