/// SPRINT-005 — Semantic labels for shell tab spaces.
library;

import '../../../core/l10n/l10n.dart';
import '../../../shared/navigation/oracly_navigation.dart';
import 'oracly_universe_realm.dart';

extension OraclyTabUniverse on OraclyTab {
  String labeled(String languageCode) => OraclyL10n.t(
        switch (this) {
          OraclyTab.home => L10nKeys.home,
          OraclyTab.coffee => 'nav.or',
          OraclyTab.astrology => 'nav.explore',
          OraclyTab.starMap => 'nav.journal',
          OraclyTab.profile => L10nKeys.profile,
        },
        languageCode: languageCode,
      );

  String get universeLabel => labeled(OraclyL10n.code);

  String get universeHint => switch (this) {
        OraclyTab.home => OraclyL10n.t('nav.hint.home'),
        OraclyTab.coffee => OraclyL10n.t('nav.hint.coffee'),
        OraclyTab.astrology => OraclyL10n.t('nav.hint.astrology'),
        OraclyTab.starMap => OraclyL10n.t('nav.hint.star'),
        OraclyTab.profile => OraclyL10n.t('nav.hint.profile'),
      };

  OraclyUniverseRealm get primaryRealm => switch (this) {
        OraclyTab.home => OraclyUniverseRealm.portal,
        OraclyTab.coffee => OraclyUniverseRealm.explore,
        OraclyTab.astrology => OraclyUniverseRealm.understand,
        OraclyTab.starMap => OraclyUniverseRealm.understand,
        OraclyTab.profile => OraclyUniverseRealm.grow,
      };
}
