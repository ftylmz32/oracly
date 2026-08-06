import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/theme/app_radius.dart';
import 'package:oracly_new/core/theme/app_spacing.dart';
import 'package:oracly_new/core/theme/craftsmanship_rhythm.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_sacred_rhythm.dart';

void main() {
  group('CraftsmanshipRhythm', () {
    test('body rhythm is shared with reading sacred rhythm', () {
      expect(
        ReadingSacredRhythm.bodyLineHeight,
        CraftsmanshipRhythm.bodyLineHeight,
      );
      expect(
        ReadingSacredRhythm.bodyLetterSpacing,
        CraftsmanshipRhythm.bodyLetterSpacing,
      );
    });

    test('vertical beats align to spacing scale', () {
      expect(CraftsmanshipRhythm.beforeInterpretation, AppSpacing.xl);
      expect(CraftsmanshipRhythm.beforeFooter, AppSpacing.sm);
      expect(CraftsmanshipRhythm.glassRadius, AppRadius.glassValue);
    });

    test('motion durations are catalogued', () {
      expect(AppDuration.appear, CraftsmanshipRhythm.appear);
      expect(AppDuration.scroll, CraftsmanshipRhythm.scroll);
      expect(AppDuration.pulse, CraftsmanshipRhythm.pulse);
      expect(AppDuration.think, CraftsmanshipRhythm.think);
    });
  });
}
