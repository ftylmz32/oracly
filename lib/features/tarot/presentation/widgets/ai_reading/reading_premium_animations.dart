/// OR-301+ / OR-434 — Staggered reveal — musical rhythm, peaks & calm.
library;

import 'package:flutter/material.dart';

import '../../theme/tarot_emotional_rhythm.dart';

/// Interpretation sections — title, then narrative, then supporting.
/// 3000ms master: 0.05 ≈ 150ms, 0.067 ≈ 200ms.
const _interpretStagger = 0.067;
const _interpretSpan = 0.16;

/// Header peak — the card arrives with intention.
const _headerSpan = 0.14;

double _window(double master, double start, double end) {
  if (master <= start) return 0;
  if (master >= end) return 1;
  return Curves.easeOutCubic.transform(
    ((master - start) / (end - start)).clamp(0.0, 1.0),
  );
}

double readingPremiumSectionProgress(int index, double master) {
  if (index >= 20) return readingPremiumGuidanceProgress(master);
  return _window(
    master,
    0.17 + index * _interpretStagger,
    0.17 + index * _interpretStagger + _interpretSpan,
  );
}

/// Story strip — card 1 has attention, later cards enter after it settles.
double readingStoryArrive(int index, double master) {
  return _window(master, 0.08 + index * 0.08, 0.24 + index * 0.08);
}

double readingStorySettle(int index, double master, int count) {
  if (index >= count - 1) return 1;
  final incoming = readingStoryArrive(index + 1, master);
  return 1.014 - incoming * 0.014;
}

double readingCardTileArrive(int index, double master) {
  return _window(master, 0.34 + index * 0.08, 0.50 + index * 0.08);
}

/// "Sana bıraktığı yön" — delayed conclusion, not a burst.
double readingPremiumGuidanceProgress(double master) {
  return _window(master, 0.70, 0.88);
}

double readingPremiumGuidanceDim(double master) {
  return Curves.easeInOut.transform(((master - 0.62) / 0.14).clamp(0.0, 1.0)) *
      0.18;
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
  final base = Curves.easeOutCubic.transform(
    ((master - start) / (end - start)).clamp(0.0, 1.0),
  );
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
