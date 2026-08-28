/// Ceremonial table first: one lead, dominant cup, then photo.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/chamber_header_lead.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_cup_hero.dart';
import 'coffee_landing_actions.dart';
import 'coffee_reference_tokens.dart';

class CoffeeLandingView extends StatelessWidget {
  const CoffeeLandingView({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onHistory,
    this.cameraEnabled = true,
    this.analysisAvailable = true,
    this.hasHistory = false,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onHistory;
  final bool cameraEnabled;
  final bool analysisAvailable;
  final bool hasHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            CoffeeReferenceTokens.screenHorizontal,
            CoffeeReferenceTokens.headerToLead,
            CoffeeReferenceTokens.screenHorizontal,
            0,
          ),
          child: ChamberHeaderLead(text: CoffeeCopy.hubLead),
        ),
        const Expanded(child: ClipRect(child: CoffeeCupHero())),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CoffeeReferenceTokens.screenHorizontal,
          ),
          child: Column(
            children: [
              if (!analysisAvailable)
                Padding(
                  padding: EdgeInsets.only(bottom: CoffeeReferenceTokens.gap),
                  child: Text(
                    CoffeeCopy.capabilityNote,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ReadingTypography.footnote(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              CoffeeLandingActions(
                onCamera: onCamera,
                onGallery: onGallery,
                onHistory: onHistory,
                hasHistory: hasHistory,
                cameraEnabled: cameraEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
