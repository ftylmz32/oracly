/// Builds compact memory from discovery profile — never raw chat or dreams.
library;

import '../../../features/personal_discovery/models/cross_discovery_insight.dart';
import '../../../features/personal_discovery/models/discovery_theme.dart';
import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../domain/models/memory_theme_stat.dart';
import '../domain/models/personal_memory_summary.dart';

abstract final class PersonalMemoryBuilder {
  PersonalMemoryBuilder._();

  static const _chatSources = {'reflection', 'conversation', 'chat'};
  static const maxThemes = 5;

  static PersonalMemorySummary fromProfile(
    PersonalDiscoveryProfile profile, {
    String? preferredName,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final themes = _themes(profile.crossInsights);
    final discoveries = _discoveries(profile);
    final prefs = <String>[
      if (profile.preferredOrStyle != null)
        'or_style:${profile.preferredOrStyle!.name}',
      if (profile.zodiacSign != null) 'sun:${profile.zodiacSign!.name}',
    ];
    final topics = [
      for (final t in themes.where((t) => t.isRecent).take(3)) t.id,
    ];
    final latest = _latest(profile, themes);
    final name = preferredName?.trim();
    final style = profile.preferredOrStyle?.name;
    final sun = profile.zodiacSign?.name;
    final fingerprint = _fingerprint(
      name: name,
      style: style,
      sun: sun,
      themes: themes,
      discoveries: discoveries,
      prefs: prefs,
      topics: topics,
      latest: latest,
    );
    return PersonalMemorySummary(
      preferredName: (name == null || name.isEmpty) ? null : name,
      orStyle: style,
      sunSign: sun,
      themes: themes,
      recentDiscoveries: discoveries,
      preferences: prefs,
      recentTopics: topics,
      latestMeaningfulDiscovery: latest,
      fingerprint: fingerprint,
      updatedAt: clock,
    );
  }

  static bool changed(
    PersonalMemorySummary previous,
    PersonalMemorySummary next,
  ) {
    if (next.isEmpty && previous.isEmpty) return false;
    return previous.fingerprint != next.fingerprint;
  }

  static List<MemoryThemeStat> _themes(List<CrossDiscoveryInsight> insights) {
    final out = <MemoryThemeStat>[];
    for (final insight in insights) {
      if (!insight.isRecurring) continue;
      if (insight.discoveryCount < 2 && insight.sourceCount < 2) continue;
      final sources = insight.sources
          .where((s) => !_chatSources.contains(s.toLowerCase()))
          .toList();
      if (sources.isEmpty) continue;
      if (insight.discoveryCount < 1) continue;
      final resolved = DiscoveryTheme.resolve(insight.theme);
      final id = resolved?.name ?? insight.theme.toLowerCase();
      out.add(
        MemoryThemeStat(
          id: id,
          label: resolved?.label ?? insight.theme,
          frequency: insight.discoveryCount,
          lastSeenAt: insight.lastObserved,
          sourceDiversity: sources.length,
          recencyWeight: insight.recencyWeight,
        ),
      );
      if (out.length >= maxThemes) break;
    }
    return List.unmodifiable(out);
  }

  static List<String> _discoveries(PersonalDiscoveryProfile profile) {
    final rows = <String>[];
    void add(String kind, int count) {
      if (count <= 0 || rows.length >= 6) return;
      rows.add('$kind:$count');
    }

    add('tarot', profile.tarotCount);
    add('coffee', profile.coffeeCount);
    add('palm', profile.palmCount);
    add('astrology', profile.astrologyCount);
    add('daily', profile.dailyMessageCount);
    add('starMap', profile.starMapCount);
    // Dream count only — never dream text.
    add('dream', profile.dreamCount);
    return List.unmodifiable(rows);
  }

  static String? _latest(
    PersonalDiscoveryProfile profile,
    List<MemoryThemeStat> themes,
  ) {
    if (themes.isEmpty) return null;
    final top = themes.first;
    final kind = profile.sourceActivity.isEmpty
        ? 'discovery'
        : profile.sourceActivity.first.source;
    if (_chatSources.contains(kind.toLowerCase())) {
      return '${top.id}@${top.lastSeenAt.toIso8601String()}';
    }
    return '$kind:${top.id}@${top.lastSeenAt.toIso8601String()}';
  }

  static String _fingerprint({
    required String? name,
    required String? style,
    required String? sun,
    required List<MemoryThemeStat> themes,
    required List<String> discoveries,
    required List<String> prefs,
    required List<String> topics,
    required String? latest,
  }) {
    final themePart = themes
        .map((t) => '${t.id}:${t.frequency}:${t.sourceDiversity}')
        .join(',');
    return [
      name ?? '',
      style ?? '',
      sun ?? '',
      themePart,
      discoveries.join(','),
      prefs.join(','),
      topics.join(','),
      latest ?? '',
    ].join('|');
  }
}
