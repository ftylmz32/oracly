/// OR-301+ / OR-434 — Staggered reveal — musical rhythm, peaks & calm.
library;

import 'package:flutter/material.dart';

import '../../theme/tarot_emotional_rhythm.dart';

/// Interpretation sections — calm, unhurried (ordinary moments).
const _interpretStagger = 0.0075;
const _interpretSpan = 0.115;

/// Header peak — the card arrives with intention.
const _headerSpan = 0.14;

double readingPremiumSectionProgress(int index, double master) {
  if (index <= 7) {
    final start = 0.06 + index * _interpretStagger;
    final end = start + _interpretSpan;
    if (master <= start) return 0;
    if (master >= end) return 1;
    return Curves.easeOutCubic.transform((master - start) / (end - start));
  }
  final start = 0.58 + (index - 8) * 0.018;
  final end = start + 0.12;
  if (master <= start) return 0;
  if (master >= end) return 1;
  return Curves.easeOutCubic.transform((master - start) / (end - start));
}

double readingPremiumHeaderProgress(double master) {
  return Curves.easeOutCubic.transform((master / _headerSpan).clamp(0.0, 1.0));
}

/// Card → title → keywords cascade within header reveal.
double readingPremiumHeaderCardProgress(double master) {
  return Curves.easeOutCubic.transform((master / 0.05).clamp(0.0, 1.0));
}

double readingPremiumHeaderTitleProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.04) / 0.08).clamp(0.0, 1.0),
  );
}

double readingPremiumHeaderSubtitleProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.10) / 0.10).clamp(0.0, 1.0),
  );
}

double readingPremiumHeaderBadgesProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.06) / 0.09).clamp(0.0, 1.0),
  );
}

/// Section title then body within each card's reveal window.
double readingPremiumSectionTitleProgress(int index, double master) {
  final base = readingPremiumSectionProgress(index, master);
  return Curves.easeOutCubic.transform((base / 0.55).clamp(0.0, 1.0));
}

double readingPremiumSectionBodyProgress(int index, double master) {
  final base = readingPremiumSectionProgress(index, master);
  return Curves.easeOutCubic.transform(
    ((base - 0.32) / 0.68).clamp(0.0, 1.0),
  );
}

/// Reflection sections — resolution beat, slower and quieter.
double readingPremiumReflectionProgress(int index, double master) {
  final offset = index - 10;
  final start = 0.76 + offset * 0.045;
  final end = start + 0.16;
  if (master <= start) return 0;
  if (master >= end) return 1;
  final base = Curves.easeOutCubic.transform((master - start) / (end - start));
  final peak = TarotEmotionalRhythm.peakPulse(
    master,
    centre: TarotEmotionalRhythm.readingReflection,
    width: 0.14,
  );
  return (base * 0.88 + peak * 0.12).clamp(0.0, 1.0);
}

/// Footer appears once the reading body is underway — actions need not wait for every section.
double readingPremiumFooterProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.55) / 0.25).clamp(0.0, 1.0),
  );
}

double readingPremiumFooterPrimaryProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.55) / 0.20).clamp(0.0, 1.0),
  );
}

double readingPremiumFooterSaveProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.58) / 0.18).clamp(0.0, 1.0),
  );
}

double readingPremiumFooterNewProgress(double master) {
  return Curves.easeOutCubic.transform(
    ((master - 0.62) / 0.18).clamp(0.0, 1.0),
  );
}
