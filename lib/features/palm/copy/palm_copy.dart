/// El Falı user-facing copy — symbolic, never medical or fatal.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/personality/or_living_voice.dart';

abstract final class PalmCopy {
  PalmCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get screenTitle => _t('palm.screen_title');
  static String get landingLine => _t('palm.landing_line');
  static String get ritualTitle => _t('palm.ritual_title');
  static String get ritualBody => _t('palm.ritual_body');
  static String get landingSteps => _t('palm.landing_steps');
  static List<String> get guidanceSteps => [
        _t('palm.step.select'),
        _t('palm.step.upload'),
        _t('palm.step.discover'),
      ];
  static String get capabilityNote => _t('palm.capability_note');
  static String get analyzeCta => _t('palm.analyze_cta');
  static String get landingCameraLabel => _t('palm.camera');
  static String get cameraLabel => _t('palm.camera');
  static String get galleryLabel => _t('palm.gallery');
  static String get previewLabel => _t('palm.preview_label');
  static String get addPhotoTitle => _t('palm.add_photo_title');
  static String get captureHeading => _t('palm.capture_heading');
  static String get captureGuide => _t('palm.capture_guide');
  static String get captureTips => _t('palm.capture_tips');
  static String get usePhotoLabel => _t('palm.use_photo');
  static String get retakeLabel => _t('palm.retake');
  static String get previewCtaHint => _t('palm.preview_cta_hint');
  static String get addPhotoHint => _t('palm.add_photo_hint');
  static String get rightHand => _t('palm.right_hand');
  static String get leftHand => _t('palm.left_hand');
  static String get handHint => _t('palm.hand_hint');
  static String get imageRequired => _t('palm.image_required');
  static String get imageMissing => _t('palm.image_missing');
  static String get imageUnreadable => _t('palm.image_unreadable');
  static String get imageTooSmall => _t('palm.image_too_small');
  static String get imageTooLarge => _t('palm.image_too_large');
  static String get imageUnsupported => _t('palm.image_unsupported');
  static String get imageNormalizeFailed => _t('palm.image_normalize_failed');
  static String get chooseAnotherPhoto => _t('palm.choose_another_photo');
  static String get retryAnalysis => _t('palm.retry_analysis');
  static String get takeawayTitle => _t('palm.takeaway_title');
  static String get themesTitle => _t('palm.themes_title');
  static String get qualityBrighten => _t('palm.quality.brighten');
  static String get qualityFrame => _t('palm.quality.frame');
  static String get qualityBlur => _t('palm.quality.blur');
  static String get qualityMissing => _t('palm.quality.missing');
  static String get qualityCloser => _t('palm.quality.closer');
  static String get qualityOneHand => _t('palm.quality.one_hand');
  static String get cameraUnavailable => _t('palm.camera_unavailable');
  static String get galleryUnavailable => _t('palm.gallery_unavailable');
  static String get analyzing =>
      OrLivingVoice.thinking(surface: OrLivingSurface.palm);
  static String get analyzingHint => _t('palm.analyzing_hint');
  static String get analysisUnavailable => _t('palm.analysis_unavailable');
  static String get analysisFailed => _t('palm.analysis_failed');
  static String get retry => _t('palm.retry');
  static String get newPalm => _t('palm.new_palm');
  static String get overallTitle => _t('palm.overall_title');
  static String get heartTitle => _t('palm.heart_title');
  static String get headTitle => _t('palm.head_title');
  static String get lifeTitle => _t('palm.life_title');
  static String get fateTitle => _t('palm.fate_title');
  static String get symbolsTitle => _t('palm.symbols_title');
  static String get disclaimer => _t('palm.disclaimer');
  static String get sourceNote => _t('palm.source_note');
}
