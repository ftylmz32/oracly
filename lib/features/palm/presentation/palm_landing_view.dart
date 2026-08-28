/// El Falı landing — intimate hero, hand choice, quiet capture invite.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/chamber_header_lead.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/palm_copy.dart';
import '../models/palm_hand.dart';
import 'palm_hand_choice.dart';
import 'palm_hero.dart';
import 'palm_landing_actions.dart';
import 'palm_tokens.dart';

class PalmLandingView extends StatelessWidget {
  const PalmLandingView({
    super.key,
    required this.hand,
    required this.onHand,
    required this.onCamera,
    required this.onGallery,
    this.cameraEnabled = true,
    this.analysisAvailable = true,
  });

  final PalmHand hand;
  final ValueChanged<PalmHand> onHand;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool cameraEnabled;
  final bool analysisAvailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChamberHeaderLead(text: PalmCopy.landingLine),
        SizedBox(height: PalmTokens.gap),
        const Expanded(child: PalmHero()),
        SizedBox(height: PalmTokens.gap),
        PalmHandChoice(
          selected: hand,
          onSelected: onHand,
        ),
        SizedBox(height: PalmTokens.gap),
        Text(
          PalmCopy.captureGuide,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ReadingTypography.footnote(
            color: PalmTokens.cream.withValues(alpha: 0.78),
          ),
        ),
        if (!analysisAvailable) ...[
          SizedBox(height: PalmTokens.gap),
          Text(
            PalmCopy.capabilityNote,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.footnote(
              color: OraclyChrome.goldLight.withValues(alpha: 0.72),
            ),
          ),
        ],
        SizedBox(height: PalmTokens.gap),
        PalmLandingActions(
          onCamera: onCamera,
          onGallery: onGallery,
          cameraEnabled: cameraEnabled,
        ),
      ],
    );
  }
}
