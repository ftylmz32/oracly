/// Evolving personal narrative — built only from stored discoveries.
library;

import '../../personal_discovery/models/theme_over_time_period.dart';

class PersonalStoryPeriod {
  const PersonalStoryPeriod({
    required this.period,
    required this.narrative,
  });

  final ThemeOverTimePeriod period;
  final String narrative;
}

class PersonalStory {
  const PersonalStory({
    required this.narrative,
    required this.periods,
    this.sourcesLine,
    required this.hasRecurringEvidence,
  });

  final String narrative;
  final List<PersonalStoryPeriod> periods;
  final String? sourcesLine;
  final bool hasRecurringEvidence;

  static const empty = PersonalStory(
    narrative: '',
    periods: [],
    hasRecurringEvidence: false,
  );
}
