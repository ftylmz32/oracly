/// Profile user-facing copy — honest account and notification states.
library;

import '../../../core/l10n/l10n.dart';

abstract final class ProfileCopy {
  ProfileCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('profile.screen_title');
  static String get guestName => _t('settings.guest_name');
  static String get premiumMember => _t('profile.premium_member');
  static String get premiumTitle => _t('profile.premium_title');
  static String get gemsTitle => _t('profile.gems_title');
  static String get historyTitle => _t('profile.history_title');
  static String get journalTitle => _t('profile.journal_title');
  static String get orTitle => _t('profile.or_title');
  static String get discoveryInsightTitle => _t('profile.insight_title');
  static String get spaceWhisper => _t('profile.space_whisper');
  static String get palmTitle => _t('profile.palm_title');
  static String get insightsTitle => _t('profile.insights_title');
  static String get dailyMessageTitle => _t('profile.daily_message');
  static String get notificationsTitle => _t('settings.notifications');
  static String get notificationsUnavailable =>
      _t('settings.notifications_unavailable');
  static String get settingsTitle => _t('settings.title');
  static String get helpTitle => _t('profile.help');
  static String get logoutTitle => _t('profile.logout');
  static String get premiumActive => _t('profile.premium_active');
  static String get nameTitle => _t('profile.name_title');
  static String get nameHint => _t('profile.name_hint');
  static String get saveLabel => _t(L10nKeys.save);
  static String get photoTitle => _t('profile.photo_title');
  static String get photoAdd => _t('profile.photo_add');
  static String get photoReplace => _t('profile.photo_replace');
  static String get photoCamera => _t('profile.photo_camera');
  static String get photoGallery => _t('profile.photo_gallery');
  static String get photoRemove => _t('profile.photo_remove');
  static String get photoUnavailable => _t('profile.photo_unavailable');
  static String get photoCameraUnavailable =>
      _t('profile.photo_camera_unavailable');
  static String get discoveriesUnit => _t('journal.discoveries');
  static String get storyEmpty => _t('profile.story_empty');
  static String get observationTitle => _t('profile.observation_title');
  static String get journalBridgeSubtitle =>
      _t('profile.journal_bridge_subtitle');
  static String get journalBridgeOpenCta =>
      _t('profile.journal_bridge_open_cta');
  static String get premiumDiscoverCta => _t('profile.premium_discover_cta');
  static String get newUserTitle => _t('profile.new_user_title');
  static String get newUserDailyCta => _t('profile.new_user_daily_cta');
  static String get newUserOrCta => _t('profile.new_user_or_cta');
  static String get newUserFirstCta => _t('profile.new_user_first_cta');
  static String get roomSection => _t('profile.room_section');
  static String get utilitySection => _t('profile.utility_section');
}
