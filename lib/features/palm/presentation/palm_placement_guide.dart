/// Empty capture frame — soft velvet stage + hand outline. No scan HUD.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/camera/guides/palm_hand_capture_guide.dart';
import '../copy/palm_copy.dart';
import 'palm_photo_frame.dart';
import 'palm_tokens.dart';

class PalmPlacementGuide extends StatelessWidget {
  const PalmPlacementGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 180.0;
        return SizedBox(
          height: h,
          child: PalmPhotoFrame(
            hero: false,
            child: ColoredBox(
              color: PalmTokens.veilInk,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 0.95,
                        colors: [
                          OraclyChrome.violet.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const PalmHandCaptureGuide(),
                  Align(
                    alignment: const Alignment(0, 0.82),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            PalmCopy.captureGuide,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ReadingTypography.secondary(
                              color: OraclyChrome.cream.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            PalmCopy.captureTips,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ReadingTypography.footnote(
                              color: OraclyChrome.goldLight.withValues(
                                alpha: 0.70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
