/// OR-431 — Sacred reading rhythm: typography, spacing, visual flow tokens.
library;

import '../../../../../core/theme/craftsmanship_rhythm.dart';

/// Calm, personal reading flow — visual only.
abstract final class ReadingSacredRhythm {
  ReadingSacredRhythm._();

  /// Multi-card strip — identify the table; interpretation stays the center.
  static const double companionCardWidth = 100;

  /// Single-card reveal — art present, not louder than the story.
  static const double heroCardWidth = 148;

  /// Long interpretation — comfortable line length, not full-bleed walls.
  static const double interpretationMaxWidth = 400;

  static const double bodyLineHeight = CraftsmanshipRhythm.bodyLineHeight;
  static const double coreLineHeight = CraftsmanshipRhythm.coreLineHeight;
  static const double bodyLetterSpacing = CraftsmanshipRhythm.bodyLetterSpacing;
  static const double reflectionLineHeight =
      CraftsmanshipRhythm.reflectionLineHeight;

  static double get afterCard => CraftsmanshipRhythm.afterCard;
  static double get afterTitle => CraftsmanshipRhythm.afterTitle;
  static double get afterKeywords => CraftsmanshipRhythm.afterKeywords;
  static double get beforeInterpretation =>
      CraftsmanshipRhythm.beforeInterpretation + 4;
  static double get betweenSections => CraftsmanshipRhythm.betweenSections;
  static double get betweenActs => CraftsmanshipRhythm.betweenActs;
  static double get beforeReflection => CraftsmanshipRhythm.beforeReflection;
  static double get afterReflection => CraftsmanshipRhythm.afterReflection;
  static double get beforeFooter => CraftsmanshipRhythm.beforeFooter;

  static double get sectionBottom => betweenSections;
}
