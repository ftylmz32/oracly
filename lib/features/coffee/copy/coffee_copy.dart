/// Kahve Falı user-facing copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';

abstract final class CoffeeCopy {
  CoffeeCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('coffee.screen_title');
  static String get landingLine => _t('coffee.landing_line');
  static String get hubLead => _t('coffee.hub_lead');
  static String get photoCta => _t('coffee.photo_cta');
  static String get ritualTease => _t('coffee.ritual_tease');
  static String get ritualTitle => _t('coffee.ritual_title');
  static String get ritualBody => _t('coffee.ritual_body');
  static String get landingSteps => _t('coffee.landing_steps');
  static List<String> get guidanceSteps => [
        _t('coffee.step.capture'),
        _t('coffee.step.upload'),
        _t('coffee.step.discover'),
      ];
  static String get previewBadge => _t('coffee.preview_badge');
  static String get capabilityNote => _t('coffee.capability_note');
  static String get landingStepsUnavailable =>
      _t('coffee.landing_steps_unavailable');
  static String get openCup => _t('coffee.open_cup');
  static String get interpretCta => _t('coffee.interpret_cta');
  static String get interpretUnavailableCta =>
      _t('coffee.interpret_unavailable');
  static String get analyzeCta => _t('coffee.analyze_cta');
  static String get historyLink => _t('coffee.history_link');
  static String get historyTitle => _t('coffee.history_title');
  static String get emptyHistory => _t('coffee.empty_history');
  static String get addPhotoTitle => _t('coffee.add_photo_title');
  static String get previewLabel => _t('coffee.preview_label');
  static String get captureGuide => _t('coffee.capture_guide');
  static String get captureTips => _t('coffee.capture_tips');
  static String get usePhotoLabel => _t('coffee.use_photo');
  static String get previewCtaHint => _t('coffee.preview_cta_hint');
  static String get addPhotoHint => _t('coffee.add_photo_hint');
  static String get cameraLabel => _t('coffee.camera');
  static String get galleryLabel => _t('coffee.gallery');
  static String get retakeLabel => _t('coffee.retake');
  static String get removeLabel => _t('coffee.remove');
  static String get imageMissing => _t('coffee.image_missing');
  static String get imageUnreadable => _t('coffee.image_unreadable');
  static String get imageTooDarkOrSmall => _t('coffee.image_unclear');
  static String get imageTooLarge => _t('coffee.image_too_large');
  static String get imageUnclear => _t('coffee.image_unclear');
  static String get imageRequired => _t('coffee.image_required');
  static String get qualityBrighten => _t('coffee.quality.brighten');
  static String get qualityFrame => _t('coffee.quality.frame');
  static String get qualityBlur => _t('coffee.quality.blur');
  static String get cameraUnavailable => _t('coffee.camera_unavailable');
  static String get cameraPermissionDenied =>
      _t('coffee.camera_permission_denied');
  static String get cameraPermissionPermanent =>
      _t('coffee.camera_permission_permanent');
  static String get galleryUnavailable => _t('coffee.gallery_unavailable');
  static String get analyzing =>
      OrLivingVoice.thinking(surface: OrLivingSurface.coffee);
  static String get analyzingSubtitle => _t('coffee.analyzing_subtitle');
  static String get analysisUnavailable => _t('coffee.analysis_unavailable');
  static String get analysisFailed => _t('coffee.analysis_failed');
  static String get retry => _t('coffee.retry');
  static String get visualTitle => _t('coffee.visual_title');
  static String get overallTitle => _t('coffee.overall_title');
  static String get overallSubtitle => _t('coffee.overall_subtitle');
  static String get symbolsTitle => _t('coffee.symbols_title');
  static String get loveTitle => _t('coffee.love_title');
  static String get careerTitle => _t('coffee.career_title');
  static String get moneyTitle => _t('coffee.money_title');
  static String get newsTitle => _t('coffee.news_title');
  static String get pathTitle => _t('coffee.path_title');
  static String get nearFutureTitle => newsTitle;
  static String get cautionTitle => _t('coffee.caution_title');
  static String get attentionTitle => cautionTitle;
  static String get takeawayTitle => cautionTitle;
  static String get disclaimer => _t('coffee.disclaimer');
  static String get sourceNote => _t('coffee.source_note');
  static String get askOr => _t('coffee.ask_or');
  static String get newCup => _t('coffee.new_cup');
}
