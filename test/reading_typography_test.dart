import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/design_system/oracly_chrome.dart';
import 'package:oracly_new/core/theme/app_spacing.dart';
import 'package:oracly_new/core/theme/craftsmanship_rhythm.dart';
import 'package:oracly_new/core/theme/reading_typography.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_sacred_rhythm.dart';

void main() {
  group('ReadingTypography', () {
    test('body rhythm matches craftsmanship and sacred rhythm', () {
      expect(
        ReadingTypography.body().height,
        CraftsmanshipRhythm.bodyLineHeight,
      );
      expect(
        ReadingTypography.body().letterSpacing,
        CraftsmanshipRhythm.bodyLetterSpacing,
      );
      expect(
        ReadingSacredRhythm.bodyLineHeight,
        CraftsmanshipRhythm.bodyLineHeight,
      );
      expect(
        ReadingTypography.body().color,
        OraclyChrome.ivory.withValues(alpha: CraftsmanshipRhythm.bodyInk),
      );
      expect(ReadingTypography.body().fontSize, greaterThanOrEqualTo(16));
    });

    test('hierarchy presets stay distinct and restrained', () {
      expect(
        ReadingTypography.display().letterSpacing,
        CraftsmanshipRhythm.displayTracking,
      );
      expect(
        ReadingTypography.pageTitle().letterSpacing,
        CraftsmanshipRhythm.pageTitleTracking,
      );
      expect(
        ReadingTypography.title().letterSpacing,
        CraftsmanshipRhythm.pageTitleTracking,
      );
      expect(
        ReadingTypography.sectionTitle().letterSpacing,
        CraftsmanshipRhythm.sectionLabelTracking,
      );
      expect(
        ReadingTypography.eyebrow().letterSpacing,
        CraftsmanshipRhythm.eyebrowTracking,
      );
      expect(
        CraftsmanshipRhythm.sectionLabelTracking,
        lessThan(1.5),
      );
      expect(
        CraftsmanshipRhythm.displayTracking,
        lessThan(1.5),
      );
      expect(ReadingTypography.secondary().fontStyle, FontStyle.normal);
      expect(ReadingTypography.metadata().fontStyle, FontStyle.normal);
      expect(ReadingTypography.micro().fontStyle, FontStyle.normal);
      expect(
        ReadingTypography.bodyCore().height,
        CraftsmanshipRhythm.coreLineHeight,
      );
      expect(
        ReadingTypography.reflection().height,
        CraftsmanshipRhythm.reflectionLineHeight,
      );
      expect(ReadingTypography.reflection().fontStyle, FontStyle.italic);
    });

    test('secondary and metadata use warm ivory, not washed gray', () {
      expect(
        ReadingTypography.secondary().color,
        OraclyChrome.ivory.withValues(alpha: CraftsmanshipRhythm.secondaryInk),
      );
      expect(
        ReadingTypography.metadata().color,
        OraclyChrome.ivory.withValues(alpha: CraftsmanshipRhythm.metadataInk),
      );
      expect(
        ReadingTypography.label().color,
        OraclyChrome.ivory.withValues(alpha: CraftsmanshipRhythm.labelInk),
      );
      expect(
        ReadingTypography.footnote().color,
        OraclyChrome.ivory.withValues(alpha: CraftsmanshipRhythm.secondaryInk),
      );
      expect(
        ReadingTypography.closing().color,
        OraclyChrome.ivory.withValues(alpha: CraftsmanshipRhythm.metadataInk),
      );
    });

    test('cta and eyebrow are present and calm', () {
      expect(
        ReadingTypography.cta().letterSpacing,
        CraftsmanshipRhythm.ctaTracking,
      );
      expect(ReadingTypography.cta().fontSize, greaterThanOrEqualTo(15));
      expect(ReadingTypography.eyebrow().fontSize, greaterThanOrEqualTo(12));
      expect(ReadingTypography.metadata().fontSize, greaterThanOrEqualTo(12));
    });

    test('opening uses reflection rhythm for card subtitle', () {
      expect(
        ReadingTypography.opening().height,
        CraftsmanshipRhythm.reflectionLineHeight,
      );
      expect(ReadingTypography.opening().fontStyle, FontStyle.italic);
    });

    test('paragraph gap aligns to spacing scale', () {
      expect(CraftsmanshipRhythm.paragraphGap, AppSpacing.sm + AppSpacing.xs);
    });
  });
}
