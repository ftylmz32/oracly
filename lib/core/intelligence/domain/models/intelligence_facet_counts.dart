/// RC-009 — Counts per journey facet for lightweight snapshot headers.
library;

import 'journey_facet.dart';

class IntelligenceFacetCounts {
  const IntelligenceFacetCounts({
    required this.readings,
    required this.favoriteCards,
    required this.recurringThemes,
    required this.reflections,
    required this.conversations,
    required this.ritualDays,
  });

  final int readings;
  final int favoriteCards;
  final int recurringThemes;
  final int reflections;
  final int conversations;
  final int ritualDays;

  int countFor(JourneyFacet facet) => switch (facet) {
        JourneyFacet.readings => readings,
        JourneyFacet.favoriteCards => favoriteCards,
        JourneyFacet.recurringThemes => recurringThemes,
        JourneyFacet.reflections => reflections,
        JourneyFacet.conversations => conversations,
        JourneyFacet.ritualHistory => ritualDays,
      };

  bool get isEmpty =>
      readings == 0 &&
      favoriteCards == 0 &&
      recurringThemes == 0 &&
      reflections == 0 &&
      conversations == 0 &&
      ritualDays == 0;
}
