/// Ceremonial landing — full plate at natural aspect; scroll when needed.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import 'coffee_cup_hero.dart';
import 'coffee_landing_actions.dart';
import 'coffee_landing_close.dart';
import 'coffee_landing_header.dart';
import 'coffee_reference_tokens.dart';

class CoffeeLandingView extends StatelessWidget {
  const CoffeeLandingView({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onHistory,
    this.cameraEnabled = true,
    this.hasHistory = false,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onHistory;
  final bool cameraEnabled;
  final bool hasHistory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CoffeeLandingHeader(),
          const CoffeeCupHero(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              CoffeeReferenceTokens.screenHorizontal,
              AppSpacing.s12,
              CoffeeReferenceTokens.screenHorizontal,
              0,
            ),
            child: CoffeeLandingActions(
              onCamera: onCamera,
              onGallery: onGallery,
              onHistory: onHistory,
              hasHistory: hasHistory,
              cameraEnabled: cameraEnabled,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            child: CoffeeLandingClose(),
          ),
          const SizedBox(height: CoffeeReferenceTokens.landingBreath),
        ],
      ),
    );
  }
}
