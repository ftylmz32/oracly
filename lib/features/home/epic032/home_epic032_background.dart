/// EPIC-032 — Approved Home atmosphere.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_cosmic_background.dart';

class HomeEpic032Background extends StatelessWidget {
  const HomeEpic032Background({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OraclyCosmicBackground(child: child);
  }
}
