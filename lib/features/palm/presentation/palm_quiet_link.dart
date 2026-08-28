/// Secondary text action — gallery; never competes with gold camera CTA.
library;

import 'package:flutter/material.dart';

import '../../../shared/widgets/oracly_quiet_link.dart';

class PalmQuietLink extends StatelessWidget {
  const PalmQuietLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyQuietLink(label: label, onTap: onTap);
  }
}
