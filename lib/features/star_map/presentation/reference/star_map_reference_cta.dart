/// Quiet Yıldızname step — brass inscription, never a gold stadium.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'star_map_reference_tokens.dart';

class StarMapReferenceCta extends StatelessWidget {
  const StarMapReferenceCta({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OraclyPressable(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
              letterSpacing: 1.8,
              color: StarMapReferenceTokens.brassGlow.withValues(alpha: 0.84),
            ),
          ),
        ),
      ),
    );
  }
}
