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
    this.allowance,
  });

  final PalmHand hand;
  final ValueChanged<PalmHand> onHand;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final bool cameraEnabled;
  final bool analysisAvailable;

  /// Freemium V1 daily allowance line; absent keeps the landing unchanged.
  final Widget? allowance;

  /// Above this text scale the Freemium landing scrolls instead of
  /// squeezing the hero (the allowance line adds height).
  static const double _scrollTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    if (allowance == null) {
      return _content(Expanded(child: PalmHero(hand: hand)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final large = MediaQuery.textScalerOf(context).scale(1) > _scrollTextScale;
        if (!large) return _content(Expanded(child: PalmHero(hand: hand)));
        final heroHeight = (constraints.maxHeight * 0.42).clamp(180.0, 360.0);
        return SingleChildScrollView(
          child: _content(
            SizedBox(height: heroHeight, child: PalmHero(hand: hand)),
          ),
        );
      },
    );
  }

  Widget _content(Widget hero) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChamberHeaderLead(text: PalmCopy.landingLine),
        SizedBox(height: PalmTokens.gap),
        hero,
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
        if (allowance != null) ...[
          SizedBox(height: PalmTokens.gap),
          allowance!,
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
