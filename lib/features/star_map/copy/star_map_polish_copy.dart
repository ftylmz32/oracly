/// Yıldızname V1 — honest, compact copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';

abstract final class StarMapPolishCopy {
  StarMapPolishCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get previewBadge => _t('star.preview');
  static String get leadLine => _t('star.lead');
  static String get storyTitle => _t('star.story_title');
  static String get journeyTitle => _t('star.journey_title');
  static String get capabilityNote => _t('star.capability');
  static String get whatItIs => capabilityNote;
  static String get enterBirthInfo => _t('star.enter_birth');
  static String get chartReady => _t('star.chart_ready');
  static String get viewChart => _t('star.view_chart');
  static String get personalizeEmpty => _t('star.personalize_empty');
  static String get generalDailyLabel => _t('star.general_daily');
  static String get personalizedDailyLabel => _t('star.personalized_daily');
  static String get todayCardTitle => _t('star.today_card');
  static String get birthChartTitle => _t('star.birth_chart_title');
  static String get birthChartHint => _t('star.birth_chart_hint');
  static String get skyMessageTitle => _t('star.sky_title');
  static String get skyMessageHint => _t('star.sky_hint');
  static String get karmicTitle => _t('star.karmic_title');
  static String get karmicResultTitle => _t('star.karmic_result');
  static String get karmicHint => _t('star.karmic_hint');
  static String get sunSignTitle => _t('star.sun_sign');
  static String get recurringThemesTitle => _t('star.journey_title');
  static String get journeyEmpty => _t('star.journey_empty');
  static String get todayReflectionTitle => _t('star.today_reflection');
  static String get planetsTitle => _t('star.planets_title');
  static String get planetsHint => _t('star.planets_hint');
  static String get skyHeadline => _t('star.sky_headline');
  static String get skyMeaning => _t('star.sky_meaning');
  static String get skyAdvice => _t('star.sky_advice');
  static String get karmicTheme => _t('star.karmic_theme');
  static String get karmicMeaning => _t('star.karmic_meaning');
  static String get karmicAsk => _t('star.karmic_ask');
  static String get leftQuestionTitle => _t('star.left_question');
  static String get karmicStep => _t('star.karmic_step');
  static String get symbolicDisclaimer => _t('star.disclaimer');
  static String get planetsCatalogueNote => _t('star.planets_note');
  static String get orHint => _t('star.or_hint');
  static String get livingLine =>
      OrLivingVoice.thinking(surface: OrLivingSurface.starMap);
  static String get toldToday => _t('star.told_today');
  static String get sunThemeTitle => _t('star.sun_theme');
  static String get innerThemeTitle => _t('star.inner_theme');
  static String get todayMirrorTitle => _t('star.today_mirror');
  static String get recentYoursTitle => _t('star.recent_yours');
}
