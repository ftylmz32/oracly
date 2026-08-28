/// OR-017 — Premium cosmic background for the home screen.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_cosmic_background.dart';

/// Full-screen home wrapper — canonical cosmic atmosphere + content.
class HomeCinematicBackground extends StatelessWidget {
  const HomeCinematicBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OraclyCosmicBackground(child: child);
  }
}

/// Static cosmic overlay — unified with app-wide [OraclyCosmicBackground].
class HomeCosmicBackground extends StatelessWidget {
  const HomeCosmicBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const OraclyCosmicBackground();
  }
}
