/// Engraved section label — KEŞFET · YANSIT · BAŞARIMLAR.
library;

import 'package:flutter/material.dart';

import '../theme/oracly_brand_signature.dart';
import '../widgets/oracly_signature_motifs.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Uppercase tracked label + optional signature divider.
class OraclySectionLabel extends StatelessWidget {
  const OraclySectionLabel({
    super.key,
    required this.label,
    this.showDivider = true,
    this.tracking = 2.8,
    this.fontSize = 11,
  });

  final String label;
  final bool showDivider;
  final double tracking;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label.toUpperCase(),
          style: OraclySignatureTypography.sectionLabel(fontSize: fontSize)
              .copyWith(
            color: AppColors.gold.withValues(alpha: 0.82),
            letterSpacing: tracking,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (showDivider) ...[
          const OraclySignatureDivider(compact: true),
          SizedBox(height: AppSpacing.s8),
        ],
      ],
    );
  }
}
