/// Compact Profile lines from a real [PersonalDiscoveryProfile].
library;

import '../../../features/discovery_journal/copy/discovery_journal_copy.dart';
import '../../../features/personal_discovery/models/cross_discovery_insight.dart';
import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../../core/l10n/oracly_format.dart';
import '../copy/profile_copy.dart';

abstract final class ProfileDiscoverySummary {
  ProfileDiscoverySummary._();

  static const maxThemes = 4;

  static int count(PersonalDiscoveryProfile profile) =>
      profile.tarotCount +
      profile.dreamCount +
      profile.coffeeCount +
      profile.reflectionCount +
      profile.palmCount;

  static List<CrossDiscoveryInsight> highlights(
    PersonalDiscoveryProfile profile,
  ) {
    return profile.crossInsights
        .where((s) => s.isRecurring)
        .take(maxThemes)
        .toList();
  }

  static String themesLine(PersonalDiscoveryProfile profile) {
    return highlights(profile).map((i) => displayTheme(i.theme)).join(' · ');
  }

  static String? metaLine(PersonalDiscoveryProfile profile) {
    final n = count(profile);
    final parts = <String>[
      if (n > 0) '$n ${ProfileCopy.discoveriesUnit}',
      if (profile.lastUpdated != null) formatDate(profile.lastUpdated!),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String chipMeta(CrossDiscoveryInsight insight) {
    final parts = <String>[
      DiscoveryJournalCopy.discoveries(insight.discoveryCount),
      formatDate(insight.lastObserved),
      DiscoveryJournalCopy.sourcesLine(insight.sources),
    ].where((p) => p.trim().isNotEmpty);
    return parts.join(' · ');
  }

  static String displayTheme(String raw) {
    return raw
        .trim()
        .split(RegExp(r'\s+'))
        .map(_title)
        .where((w) => w.isNotEmpty)
        .join(' ');
  }

  static String formatDate(DateTime d) => OraclyFormat.dateNumeric(d);

  static String _title(String word) {
    if (word.isEmpty) return word;
    final first = word.substring(0, 1);
    final upper = switch (first) {
      'i' => 'İ',
      'ı' => 'I',
      _ => first.toUpperCase(),
    };
    return '$upper${word.substring(1)}';
  }
}
