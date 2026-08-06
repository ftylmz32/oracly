/// OR-401 / OR-407 — Luxury crystal panel for spread selection.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import 'oracly_sacred_identity.dart';

/// Carved mystical crystal surface — depth, glow, gold facets.
class TarotHomeCrystalPanel extends StatelessWidget {
  const TarotHomeCrystalPanel({
    super.key,
    required this.child,
    this.padding,
    this.lightTier = OraclyLightTier.upperChamber,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final OraclyLightTier lightTier;

  @override
  Widget build(BuildContext context) {
    return OraclyCrystalFrame(
      kind: OraclyCrystalFrameKind.panel,
      radius: AppRadius.xl,
      lightTier: lightTier,
      padding: padding,
      showOrnaments: false,
      showStars: false,
      child: child,
    );
  }
}
