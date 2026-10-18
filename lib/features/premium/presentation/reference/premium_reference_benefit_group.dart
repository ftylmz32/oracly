/// Labeled group of premium rows inside the benefits card.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';

class PremiumReferenceBenefitGroup extends StatelessWidget {
  const PremiumReferenceBenefitGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(),
        ),
        SizedBox(height: AppSpacing.s12),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s12),
          children[i],
        ],
      ],
    );
  }
}
