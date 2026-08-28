/// Settings honesty copy — never imply a control that does nothing.
library;

import '../../../core/l10n/l10n.dart';

abstract final class SettingsCopy {
  SettingsCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get soon => _t('common.coming_soon');
  static String get darkTitle => _t('settings.theme.dark');
  static String get darkSubtitle => _t('settings.theme_subtitle');
  static String get themeSubtitle => _t('settings.theme_subtitle');
  static String get languageTitle => _t('settings.language');
  static String get languageSubtitle => _t('settings.language_subtitle');
  static String get notificationsTitle => _t('settings.notifications');
  static String get notificationsSubtitle =>
      _t('settings.notifications_subtitle');
  static String get notificationsUnavailable =>
      _t('settings.notifications_unavailable');
  static String get animationTitle => _t('settings.animation');
  static String get animationSubtitle => _t('settings.animation_subtitle');
  static String get animationUnavailable =>
      _t('settings.animation_unavailable');
  static String get soundTitle => _t('settings.sound');
  static String get soundSubtitle => _t('settings.sound_subtitle');
  static String get ambientMusicTitle => _t('settings.ambient_music');
  static String get ambientMusicSubtitle =>
      _t('settings.ambient_music_subtitle');
  static String get atmosphereTitle => _t('settings.atmosphere');
  static String get atmosphereSubtitle => _t('settings.atmosphere_subtitle');
  static String get voiceRepliesTitle => _t('settings.output');
  static String get voiceRepliesSubtitle => _t('settings.output_subtitle');
  static String get outputTitle => _t('settings.output');
  static String get outputText => _t('or.output_text');
  static String get outputVoice => _t('or.output_voice');
  static String get outputModeText => _t('or.output_mode.text');
  static String get outputModeVoice => _t('or.output_mode.voice');
  static String get outputModeConversation =>
      _t('or.output_mode.conversation');
  static String get hapticTitle => _t('settings.haptic');
  static String get hapticSubtitle => _t('settings.haptic_subtitle');
  static String get orStyleTitle => _t('settings.or_style');
  static String get orStyleSubtitle => _t('settings.or_style_subtitle');
  static String get orStyleSheetTitle => _t('settings.or_style_sheet');
}
