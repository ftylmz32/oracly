/// Camera primary. Gallery stays a quiet inscription.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../copy/palm_copy.dart';
import 'palm_quiet_link.dart';
import 'palm_tokens.dart';

class PalmLandingActions extends StatelessWidget {
  const PalmLandingActions({
    super.key,
    required this.onCamera,
    required this.onGallery,
    this.cameraEnabled = true,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool cameraEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.pillRadius,
            boxShadow: [
              BoxShadow(
                color: OraclyChrome.gold.withValues(
                  alpha: OraclyChrome.glowMedium,
                ),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: OraclyGoldButton(
            label: PalmCopy.landingCameraLabel,
            onPressed: cameraEnabled ? onCamera : null,
            icon: Icons.photo_camera_outlined,
            expanded: true,
          ),
        ),
        SizedBox(height: PalmTokens.gap),
        PalmQuietLink(
          label: PalmCopy.galleryLabel,
          onTap: onGallery,
        ),
      ],
    );
  }
}
