/// Left / right palm selector — obvious, luxurious, never noisy.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/palm_copy.dart';
import '../models/palm_hand.dart';
import 'palm_hand_tile.dart';
import 'palm_tokens.dart';

class PalmHandChoice extends StatelessWidget {
  const PalmHandChoice({
    super.key,
    required this.selected,
    required this.onSelected,
    this.showHint = true,
  });

  final PalmHand selected;
  final ValueChanged<PalmHand> onSelected;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showHint) ...[
          Text(
            PalmCopy.handHint,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.footnote(
              color: OraclyChrome.goldLight.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: PalmTokens.gap),
        ],
        Row(
          children: [
            Expanded(
              child: PalmHandTile(
                hand: PalmHand.left,
                label: PalmCopy.leftHand,
                selected: selected == PalmHand.left,
                onTap: () => onSelected(PalmHand.left),
              ),
            ),
            SizedBox(width: PalmTokens.gap + 4),
            Expanded(
              child: PalmHandTile(
                hand: PalmHand.right,
                label: PalmCopy.rightHand,
                selected: selected == PalmHand.right,
                onTap: () => onSelected(PalmHand.right),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
