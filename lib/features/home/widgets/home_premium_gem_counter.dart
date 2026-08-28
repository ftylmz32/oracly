/// EPIC-017 / EPIC-022 — Premium gem counter for the home status bar.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_crystal_capsule.dart';

/// Canonical gem chip — delegates to [OraclyCrystalCapsule].
class HomePremiumGemCounter extends StatelessWidget {
  const HomePremiumGemCounter({
    super.key,
    required this.count,
    this.onTap,
  });

  final String count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyCrystalCapsule(count: count, onTap: onTap);
  }
}
