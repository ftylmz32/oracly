/// EPIC-031 — Wide metallic gold stadium CTA (canonical gold language).
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/oracly_gold_button.dart';

class TarotEpic031PrimaryButton extends StatelessWidget {
  const TarotEpic031PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OraclyGoldButton(
      label: label,
      onPressed: onPressed,
      icon: Icons.auto_awesome,
      expanded: true,
    );
  }
}
