/// Copy for Premium — Draw Your Soulmate.
library;

import '../../../core/l10n/l10n.dart';

abstract final class SoulMateCopy {
  SoulMateCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get listTitle => _t('soulmate.list_title');
  static String get listDescription => _t('soulmate.list_description');
  static String get listDescriptionSaved => _t('soulmate.list_description_saved');
  static String get screenTitle => _t('soulmate.screen_title');
  static String get screenLead => _t('soulmate.screen_lead');
  static String get honesty => _t('soulmate.honesty');
  static String get interpretationLabel => _t('soulmate.interpretation');
  static String get energyLabel => _t('soulmate.energy');
  static String get attractionLabel => _t('soulmate.attraction');
  static String get dynamicsLabel => _t('soulmate.dynamics');
  static String get feelingLabel => _t('soulmate.feeling');
  static String get yourSideLabel => _t('soulmate.your_side');
  static String get symbolicLabel => _t('soulmate.symbolic');
  static String get brandMark => _t('soulmate.brand');
  static String get nameLabel => _t('soulmate.name_label');
  static String get nameHint => _t('soulmate.name_hint');
  static String get formWhy => _t('soulmate.form_why');
  static String get birthLabel => _t('soulmate.birth_label');
  static String get birthHint => _t('soulmate.birth_hint');
  static String get genderLabel => _t('soulmate.gender_label');
  static String get genderHint => _t('soulmate.gender_hint');
  static String get genderFeminine => _t('soulmate.gender_feminine');
  static String get genderMasculine => _t('soulmate.gender_masculine');
  static String get intentionLabel => _t('soulmate.intention_label');
  static String get intentionHint => _t('soulmate.intention_hint');
  static String get drawCta => _t('soulmate.draw_cta');
  static String get redrawCta => _t('soulmate.redraw_cta');
  static String get drawing => _t('soulmate.drawing');
  static String get drawingPhase2 => _t('soulmate.drawing_2');
  static String get drawingPhase3 => _t('soulmate.drawing_3');
  static List<String> get drawingPhases => [drawing, drawingPhase2, drawingPhase3];
  static String get unavailable => _t('soulmate.unavailable');
  static String get retry => _t('soulmate.retry');
  static String get nameRequired => _t('soulmate.name_required');
  static String get birthRequired => _t('soulmate.birth_required');
  static String get premiumRequired => _t('soulmate.premium_required');
  static String get portraitSemantics => _t('soulmate.portrait_semantics');
}
