/// Empty coffee capture — cup interior framing before the chamber opens.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_hero_stage.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/camera/guides/coffee_cup_capture_guide.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_reference_tokens.dart';

class CoffeeCupPlacementGuide extends StatelessWidget {
  const CoffeeCupPlacementGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 180.0;
        return OraclyGlassCard(
          height: h,
          borderRadius: CoffeeReferenceTokens.heroRadius,
          premium: true,
          glowStrength: 1.02,
          padding: EdgeInsets.zero,
          child: ChamberHeroStage(
            warm: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoffeeCupCaptureGuide(
                  tip: CoffeeCopy.captureGuide,
                  detail: CoffeeCopy.captureTips,
                ),
                Align(
                  alignment: const Alignment(0, -0.86),
                  child: Text(
                    CoffeeCopy.ritualTease,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.eyebrow(
                      fontSize: 11,
                      color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
