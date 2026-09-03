/// Capture guidance copy — title, helper, compact tips.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/palm_copy.dart';
import 'palm_tokens.dart';

class PalmCaptureGuideHeader extends StatelessWidget {
  const PalmCaptureGuideHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      PalmCopy.captureHeading,
      textAlign: TextAlign.center,
      style: ReadingTypography.display(
        color: OraclyChrome.goldLight,
      ).copyWith(
        fontSize: 21,
        letterSpacing: 0.8,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class PalmCaptureGuideHelper extends StatelessWidget {
  const PalmCaptureGuideHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      PalmCopy.captureGuide,
      textAlign: TextAlign.center,
      style: ReadingTypography.secondary(
        color: PalmTokens.cream.withValues(alpha: 0.88),
      ).copyWith(height: 1.35, fontSize: 14),
    );
  }
}

class PalmCaptureGuideTips extends StatelessWidget {
  const PalmCaptureGuideTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Text(
        PalmCopy.captureTips,
        textAlign: TextAlign.center,
        style: ReadingTypography.footnote(
          color: OraclyChrome.goldLight.withValues(alpha: 0.76),
        ).copyWith(letterSpacing: 0.6, height: 1.35),
      ),
    );
  }
}