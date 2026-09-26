/// Calm epilogue — lighter than summary, not another chapter lane.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';

class StarMapResultClosing extends StatelessWidget {
  const StarMapResultClosing({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return OraclySoftReveal(
      child: Padding(
        padding: EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.md,
        ),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.sectionLabel(
                    color: OraclyChrome.goldPrimary.withValues(alpha: 0.78),
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: ReadingTypography.closing(
                  color: OraclyChrome.cream.withValues(alpha: 0.86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
