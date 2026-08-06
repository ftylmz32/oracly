/// OR-431 — Sacred reading rhythm: typography, spacing, visual flow tokens.
library;

import '../../../../../core/theme/craftsmanship_rhythm.dart';

/// Calm, personal reading flow — visual only.
abstract final class ReadingSacredRhythm {
  ReadingSacredRhythm._();

  /// Companion card — present but smaller than reveal.
  static const double companionCardWidth = 88;

  /// Body copy — generous, never intimidating.
  static const double bodyLineHeight = CraftsmanshipRhythm.bodyLineHeight;
  static const double coreLineHeight = CraftsmanshipRhythm.coreLineHeight;
  static const double bodyLetterSpacing = CraftsmanshipRhythm.bodyLetterSpacing;
  static const double reflectionLineHeight =
      CraftsmanshipRhythm.reflectionLineHeight;

  /// Vertical breathing room between major beats.
  static double get afterCard => CraftsmanshipRhythm.afterCard;
  static double get afterTitle => CraftsmanshipRhythm.afterTitle;
  static double get afterKeywords => CraftsmanshipRhythm.afterKeywords;
  static double get beforeInterpretation => CraftsmanshipRhythm.beforeInterpretation;
  static double get betweenSections => CraftsmanshipRhythm.betweenSections;
  static double get betweenActs => CraftsmanshipRhythm.betweenActs;
  static double get beforeReflection => CraftsmanshipRhythm.beforeReflection;
  static double get afterReflection => CraftsmanshipRhythm.afterReflection;
  static double get beforeFooter => CraftsmanshipRhythm.beforeFooter;

  static double get sectionBottom => betweenSections;
}
