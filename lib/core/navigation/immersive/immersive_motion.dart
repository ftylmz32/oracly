/// EPIC-025 — Canonical motion tokens for immersive navigation.
library;

import 'package:flutter/material.dart';

/// Unified timing and spatial values for page, section, and overlay motion.
abstract final class ImmersiveMotion {
  ImmersiveMotion._();

  // ── Page enter (EPIC-025 spec) — soft ease, small lift, never flashy ─────
  static const Duration pageEnter = Duration(milliseconds: 440);
  static const Duration pageExit = Duration(milliseconds: 320);
  /// Soft decelerate — premium settle, not linear platform fade.
  static const Curve pageEnterCurve = Cubic(0.22, 0.74, 0.18, 1.0);
  static const Curve pageExitCurve = Curves.easeInCubic;

  static const double pageEnterScaleBegin = 0.988;
  static const double pageEnterScaleEnd = 1.0;
  static const double pageEnterTranslatePx = 14;
  static const double pageExitTranslatePx = 5;
  static const double pageExitFadeAmount = 0.10;

  // ── Tab cross-fade ───────────────────────────────────────────────────────
  static const Duration tabCrossFade = Duration(milliseconds: 380);

  // ── Section entrance ─────────────────────────────────────────────────────
  static const Duration sectionEnter = Duration(milliseconds: 440);
  static const double sectionEnterOffsetPx = 14;
  static const double sectionEnterScaleBegin = 0.988;
  static const Duration sectionStaggerStep = Duration(milliseconds: 56);

  // ── Overlay / modal ──────────────────────────────────────────────────────
  static const Duration overlayEnter = Duration(milliseconds: 380);
  static const Duration overlayExit = Duration(milliseconds: 280);
  static const double overlayScaleBegin = 0.975;
  static const double overlayBarrierOpacity = 0.55;

  // ── Bottom navigation ────────────────────────────────────────────────────
  static const Duration navSelect = Duration(milliseconds: 420);
  static const double navActiveScale = 1.04;
  static const double navBarHeight = 68;
  static const double navBarMarginH = 20;
  static const double navBarMarginBottom = 12;
  static const double navBarBlur = 28;
}
