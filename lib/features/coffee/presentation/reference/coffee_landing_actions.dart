/// Gold photo pill and outline gallery — medium width, not edge-to-edge.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_gallery_cta.dart';
import 'coffee_or_divider.dart';
import 'coffee_quiet_link.dart';
import 'coffee_reference_tokens.dart';

class CoffeeLandingActions extends StatelessWidget {
  const CoffeeLandingActions({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onHistory,
    required this.hasHistory,
    this.cameraEnabled = true,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onHistory;
  final bool hasHistory;
  final bool cameraEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ctaW =
            constraints.maxWidth * CoffeeReferenceTokens.ctaWidthFactor;
        return Column(
          children: [
            SizedBox(
              width: ctaW,
              child: OraclyGoldButton(
                label: CoffeeCopy.photoCta,
                icon: Icons.photo_camera_outlined,
                expanded: true,
                onPressed: cameraEnabled ? onCamera : null,
              ),
            ),
            SizedBox(width: ctaW, child: const CoffeeOrDivider()),
            SizedBox(width: ctaW, child: CoffeeGalleryCta(onTap: onGallery)),
            if (hasHistory) ...[
              const SizedBox(height: AppSpacing.s8),
              CoffeeQuietLink(
                label: CoffeeCopy.historyLink,
                onTap: onHistory,
                muted: true,
              ),
            ],
            const SizedBox(height: AppSpacing.s4),
          ],
        );
      },
    );
  }
}
