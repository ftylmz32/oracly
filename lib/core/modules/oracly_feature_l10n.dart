/// Localized titles for [OraclyFeatureModule] — catalogues stay TR for ids.
library;

import '../l10n/l10n.dart';
import 'oracly_feature_id.dart';
import 'oracly_feature_module.dart';

extension OraclyFeatureL10n on OraclyFeatureModule {
  String get labeled => OraclyL10n.t(switch (id) {
        OraclyFeatureId.tarot => L10nKeys.tarotReading,
        OraclyFeatureId.coffee => L10nKeys.coffee,
        OraclyFeatureId.palm => 'profile.palm_title',
        OraclyFeatureId.aiChat => L10nKeys.aiChat,
        OraclyFeatureId.dailyEnergy => 'ritual.title',
        OraclyFeatureId.dream => L10nKeys.dream,
        OraclyFeatureId.astrology => L10nKeys.astrology,
        OraclyFeatureId.starMap => L10nKeys.starMap,
        OraclyFeatureId.readingHistory => 'feature.history',
        OraclyFeatureId.discoveryJournal => 'profile.journal_title',
        OraclyFeatureId.personalInsights => 'insights.title',
        OraclyFeatureId.dailyMessage => 'daily_msg.list_title',
        OraclyFeatureId.memory => 'feature.memory',
        OraclyFeatureId.achievements => 'achievements.title',
        OraclyFeatureId.premium => L10nKeys.premiumTitle,
        OraclyFeatureId.settings => 'feature.settings_row',
        OraclyFeatureId.numerology => L10nKeys.numerology,
        OraclyFeatureId.moonCalendar => L10nKeys.moonCalendar,
        OraclyFeatureId.manifestation => L10nKeys.manifestation,
        OraclyFeatureId.home => L10nKeys.home,
        OraclyFeatureId.profile => L10nKeys.profile,
        OraclyFeatureId.soulMate => 'soulmate.list_title',
      });

  String? get labeledSubtitle {
    final key = switch (id) {
      OraclyFeatureId.tarot => 'home.tarot.caption',
      OraclyFeatureId.coffee => 'feature.coffee.sub',
      OraclyFeatureId.palm => 'feature.palm.sub',
      OraclyFeatureId.aiChat => 'feature.or.sub',
      OraclyFeatureId.dailyEnergy => 'feature.ritual.sub',
      OraclyFeatureId.dream => 'feature.dream.sub',
      OraclyFeatureId.astrology => 'feature.astro.sub',
      OraclyFeatureId.starMap => 'feature.star.sub',
      OraclyFeatureId.readingHistory => 'feature.history.sub',
      OraclyFeatureId.discoveryJournal => 'feature.journal.sub',
      OraclyFeatureId.dailyMessage => 'feature.message.sub',
      OraclyFeatureId.personalInsights => 'feature.insights.sub',
      OraclyFeatureId.memory => 'feature.memory.sub',
      OraclyFeatureId.achievements => 'feature.achievements.sub',
      OraclyFeatureId.premium => 'feature.premium.sub',
      OraclyFeatureId.settings => 'feature.settings.sub',
      OraclyFeatureId.numerology => 'feature.numerology.sub',
      OraclyFeatureId.moonCalendar => 'feature.moon.sub',
      OraclyFeatureId.manifestation => 'feature.manifest.sub',
      OraclyFeatureId.soulMate => 'soulmate.list_description',
      _ => null,
    };
    return key == null ? null : OraclyL10n.t(key);
  }
}
