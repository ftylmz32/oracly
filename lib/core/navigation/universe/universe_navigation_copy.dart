/// SPRINT-005 — Universe navigation language (structure, not visual identity).
library;

import '../../l10n/l10n.dart';

abstract final class UniverseNavigationCopy {
  UniverseNavigationCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get tabHome => _t(L10nKeys.home);
  static String get tabCoffee => _t(L10nKeys.coffee);
  static String get tabAstrology => _t(L10nKeys.astrology);
  static String get tabStarMap => _t(L10nKeys.starMap);
  static String get tabProfile => _t(L10nKeys.profile);

  static String get tabHomeHint => _t('nav.hint.home');
  static String get tabCoffeeHint => _t('nav.hint.coffee');
  static String get tabAstrologyHint => _t('nav.hint.astrology');
  static String get tabStarMapHint => _t('nav.hint.star');
  static String get tabProfileHint => _t('nav.hint.profile');

  static String get tabUniverse => tabHome;
  static String get tabTarot => tabCoffee;
  static String get tabRitual => tabCoffee;
  static String get tabReflect => _t('nav.reflect');
  static String get tabJourney => tabProfile;

  static String get tabUniverseHint => tabHomeHint;
  static String get tabTarotHint => tabCoffeeHint;
  static String get tabRitualHint => tabCoffeeHint;
  static String get tabReflectHint => _t('nav.hint.reflect');
  static String get tabJourneyHint => tabProfileHint;

  static String get bandExplore => _t('band.explore');
  static String get bandReflect => _t('band.reflect');
  static String get bandUnderstand => _t('band.understand');

  static String get bandExploreHint => _t('band.explore_hint');
  static String get bandReflectHint => _t('band.reflect_hint');
  static String get bandUnderstandHint => _t('band.understand_hint');

  static String get sectionRemember => _t('section.remember');
  static String get sectionGrow => _t('section.grow');
  static String get sectionAccount => _t('section.account');

  static String get sectionRememberHint => _t('section.remember_hint');
  static String get sectionGrowHint => _t('section.grow_hint');
  static String get sectionAccountHint => _t('section.account_hint');

  static String get mapTitle => _t('map.title');
  static String get mapIntro => _t('map.intro');

  static String get realmPortal => _t('realm.portal');
  static String get realmExplore => _t('realm.explore');
  static String get realmReflect => _t('realm.reflect');
  static String get realmUnderstand => _t('realm.understand');
  static String get realmRemember => _t('realm.remember');
  static String get realmGrow => _t('realm.grow');

  static String get realmPortalHint => _t('realm.portal_hint');
  static String get realmExploreHint => _t('realm.explore_hint');
  static String get realmReflectHint => _t('realm.reflect_hint');
  static String get realmUnderstandHint => _t('realm.understand_hint');
  static String get realmRememberHint => _t('realm.remember_hint');
  static String get realmGrowHint => _t('realm.grow_hint');
}
