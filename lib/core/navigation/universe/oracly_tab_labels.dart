/// SPRINT-005 — Semantic labels for shell tab spaces.
library;

import '../../../shared/navigation/oracly_navigation.dart';
import 'oracly_universe_realm.dart';
import 'universe_navigation_copy.dart';

extension OraclyTabUniverse on OraclyTab {
  String get universeLabel => switch (this) {
        OraclyTab.home => UniverseNavigationCopy.tabUniverse,
        OraclyTab.tarot => UniverseNavigationCopy.tabRitual,
        OraclyTab.chat => UniverseNavigationCopy.tabReflect,
        OraclyTab.profile => UniverseNavigationCopy.tabJourney,
      };

  String get universeHint => switch (this) {
        OraclyTab.home => UniverseNavigationCopy.tabUniverseHint,
        OraclyTab.tarot => UniverseNavigationCopy.tabRitualHint,
        OraclyTab.chat => UniverseNavigationCopy.tabReflectHint,
        OraclyTab.profile => UniverseNavigationCopy.tabJourneyHint,
      };

  OraclyUniverseRealm get primaryRealm => switch (this) {
        OraclyTab.home => OraclyUniverseRealm.portal,
        OraclyTab.tarot => OraclyUniverseRealm.explore,
        OraclyTab.chat => OraclyUniverseRealm.reflect,
        OraclyTab.profile => OraclyUniverseRealm.grow,
      };
}
