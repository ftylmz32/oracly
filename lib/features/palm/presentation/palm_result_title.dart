/// Private reading title — calm after the hand settles.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/palm_copy.dart';
import '../models/palm_hand.dart';

class PalmResultTitle extends StatelessWidget {
  const PalmResultTitle({super.key, required this.hand});

  final PalmHand hand;

  @override
  Widget build(BuildContext context) {
    final handLabel =
        hand == PalmHand.left ? PalmCopy.leftHand : PalmCopy.rightHand;
    return Padding(
      padding: EdgeInsets.only(top: CraftsmanshipRhythm.afterTitle),
      child: Column(
        children: [
          Text(
            handLabel,
            textAlign: TextAlign.center,
            style: ReadingTypography.eyebrow(
              fontSize: 11,
              color: OraclyChrome.goldLight.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: CraftsmanshipRhythm.afterTitle),
          Text(
            PalmCopy.overallTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.title(),
          ),
        ],
      ),
    );
  }
}
