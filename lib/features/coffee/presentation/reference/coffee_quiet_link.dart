/// Secondary text action — gallery / history; never competes with gold CTA.
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/oracly_quiet_link.dart';

class CoffeeQuietLink extends StatelessWidget {
  const CoffeeQuietLink({
    super.key,
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return OraclyQuietLink(label: label, onTap: onTap, muted: muted);
  }
}
