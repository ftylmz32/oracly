/// Astrology presentation copy — sun-sign reading, never natal invention.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';

abstract final class AstrologyPresentationCopy {
  AstrologyPresentationCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get todayTitle => _t('astro.today_title');
  static String get leadLine => _t('astro.lead');
  static String get loadingSky => _t('astro.loading_today_sky');
  static String get unavailableMoreInfo => _t('astro.unavailable_more_info');
  static String get yourSkyTitle => _t('astro.your_sky_title');
  static String get livingLine =>
      OrLivingVoice.thinking(surface: OrLivingSurface.astrology);
  static String get generalTitle => _t('astro.general');
  static String get loveTitle => _t('astro.love');
  static String get careerTitle => _t('astro.career');
  static String get innerTitle => _t('astro.inner');
  static String get recurringLabel => _t('astro.recurring');
  static String get journeyEmpty => _t('astro.journey_empty');
  static String get detailCta => _t('astro.detail_cta');
  static String get todayAsk => _t('astro.today_ask');
  static String get laneLove => _t('astro.lane_love');
  static String get laneWork => _t('astro.lane_work');
  static String get laneInner => _t('astro.lane_inner');
  static String get reportTheme => _t('astro.report_theme');
  static String get reportMessage => _t('astro.report_message');
  static String get reportAttention => _t('astro.report_attention');
  static String get reportNext => _t('astro.report_next');
  static String get reportDepths => _t('astro.report_depths');
}
