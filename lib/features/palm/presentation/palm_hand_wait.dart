/// Wait over the real palm photo — premium analysis canvas, never a spinner.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import 'palm_analysis_canvas.dart';

class PalmHandWait extends StatelessWidget {
  const PalmHandWait({
    super.key,
    required this.message,
    required this.path,
    this.subtitle,
  });

  final String message;
  final String path;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    // Parent screen already applies side padding — avoid double inset.
    return Column(
      children: [
        Expanded(
          child: PalmAnalysisCanvas(path: path, contain: true),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: ReadingTypography.opening(
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: OraclyChrome.cream.withValues(alpha: 0.72),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
