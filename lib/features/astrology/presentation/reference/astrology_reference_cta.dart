/// Gold follow-up after the story — full-width pill, never on the hero.
library;

import 'package:flutter/material.dart';

import '../../../../shared/widgets/oracly_gold_button.dart';

class AstrologyReferenceCta extends StatelessWidget {
  const AstrologyReferenceCta({
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
      expanded: true,
      onPressed: onPressed,
    );
  }
}
