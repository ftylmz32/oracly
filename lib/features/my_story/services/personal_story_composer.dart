/// Composes BENİM HİKÂYEM from observable discovery evidence only.
library;

import '../../discovery_journal/copy/discovery_journal_copy.dart';
import '../../discovery_journal/copy/discovery_journal_over_time_copy.dart';
import '../../personal_discovery/copy/personal_theme_copy.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../../personal_discovery/services/theme_over_time_builder.dart';
import '../models/personal_story.dart';

abstract final class PersonalStoryComposer {
  PersonalStoryComposer._();

  static PersonalStory compose(
    PersonalDiscoveryProfile profile, {
    DateTime? now,
  }) {
    try {
      final crossModal = profile.crossInsights
          .where((i) => i.isRecurring && i.isCrossModal)
          .toList();
      final themes = crossModal.map((i) => i.theme).take(3).toList();

      final narrative = switch (themes.length) {
        0 when !profile.hasHistory => PersonalThemeCopy.insufficient,
        0 => PersonalThemeCopy.accumulating,
        _ => PersonalThemeCopy.crossModal(themes),
      };

      final periods = [
        for (final comparison
            in ThemeOverTimeBuilder.fromObservations(profile.observations, now: now))
          PersonalStoryPeriod(
            period: comparison.period,
            narrative: DiscoveryJournalOverTimeCopy.narrative(comparison),
          ),
      ];

      String? sourcesLine;
      if (crossModal.isNotEmpty) {
        final sources = {
          for (final insight in crossModal) ...insight.sources,
        }.toList()
          ..sort();
        if (sources.length >= 2) {
          sourcesLine = DiscoveryJournalCopy.sourcesLine(sources);
        }
      }

      return PersonalStory(
        narrative: narrative,
        periods: periods,
        sourcesLine: sourcesLine,
        hasRecurringEvidence: themes.isNotEmpty,
      );
    } catch (_) {
      return PersonalStory.empty;
    }
  }
}
