/// Shared accessibility floors — touch, readable gold, quiet actions, text scale.
library;

import 'package:flutter/material.dart';

/// Canonical a11y metrics. Visual chrome stays premium; targets stay usable.
abstract final class OraclyA11y {
  OraclyA11y._();

  /// WCAG-minded minimum interactive size (logical px).
  static const double minTouchTarget = 44;

  /// App-wide soft text scale ceiling — prevents severe chrome overflow.
  static const double maxAppTextScale = 1.4;

  /// Compact chrome (nav labels) — scale gently, never balloon the bar.
  static const double maxChromeTextScale = 1.2;

  static const double minAppTextScale = 0.85;

  /// Readable gold on dark glass / imagery (interactive labels).
  static const double goldOnDark = 0.90;

  /// Secondary quiet-link gold (gallery / retake) — still subordinate to CTA.
  static const double quietGold = 0.88;

  /// Muted quiet link (history) — readable, never washed out.
  static const double quietGoldMuted = 0.80;

  /// Supporting cream on dark velvet.
  static const double secondaryCream = 0.80;

  /// Hint / footnote cream — soft, not invisible.
  static const double hintCream = 0.70;

  /// Inactive icon / micro action gold — still legible.
  static const double iconGoldIdle = 0.78;

  static Color goldReadable([Color? base]) =>
      (base ?? const Color(0xFFF4DB94)).withValues(alpha: goldOnDark);

  static Color creamSecondary([Color? base]) =>
      (base ?? const Color(0xFFF3EADF)).withValues(alpha: secondaryCream);

  static Color creamHint([Color? base]) =>
      (base ?? const Color(0xFFF3EADF)).withValues(alpha: hintCream);

  static TextScaler clampAppTextScaler(TextScaler raw) => raw.clamp(
        minScaleFactor: minAppTextScale,
        maxScaleFactor: maxAppTextScale,
      );

  static TextScaler clampChromeTextScaler(TextScaler raw) => raw.clamp(
        minScaleFactor: minAppTextScale,
        maxScaleFactor: maxChromeTextScale,
      );

  /// Soft-clamp text scale for compact chrome without affecting body reading.
  static Widget chromeTextScale({required Widget child}) {
    return Builder(
      builder: (context) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: clampChromeTextScaler(media.textScaler),
          ),
          child: child,
        );
      },
    );
  }

  static Widget ensureMinTouch({
    required Widget child,
    double min = minTouchTarget,
    Alignment alignment = Alignment.center,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: min, minHeight: min),
      child: Align(alignment: alignment, child: child),
    );
  }
}
