/// Gold photo pill dominates. Gallery stays a quiet inscription.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_ornament_heading.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../copy/coffee_copy.dart';
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
    return Column(
      children: [
        OraclyGoldButton(
          label: CoffeeCopy.photoCta,
          icon: Icons.photo_camera_outlined,
          expanded: true,
          onPressed: cameraEnabled ? onCamera : null,
        ),
        SizedBox(height: CoffeeReferenceTokens.gap),
        CoffeeQuietLink(
          label: CoffeeCopy.galleryLabel,
          onTap: onGallery,
        ),
        ChamberOrnamentHeading(label: CoffeeCopy.overallTitle),
        if (hasHistory)
          CoffeeQuietLink(
            label: CoffeeCopy.historyLink,
            onTap: onHistory,
            muted: true,
          ),
      ],
    );
  }
}
