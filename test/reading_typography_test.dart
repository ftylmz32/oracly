import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/theme/app_colors.dart';
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
    });

    test('semantic presets use distinct line heights', () {
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

    test('footnote and closing use muted secondary colors by default', () {
      expect(ReadingTypography.footnote().color, AppColors.textHint);
      expect(ReadingTypography.closing().color, AppColors.textMuted);
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
