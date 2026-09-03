/// Reflection quote card — AI closing or calm generic line.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';

class DreamResultReflectionCard extends StatelessWidget {
  const DreamResultReflectionCard({
    super.key,
    required this.quote,
  });

  final String quote;

  @override
  Widget build(BuildContext context) {
    if (quote.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OraclyChrome.violet.withValues(alpha: 0.22),
              const Color(0xFF120A1E).withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: 0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“',
                style: ReadingTypography.title(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.5),
                ).copyWith(fontSize: 28, height: 0.8),
              ),
              Text(
                quote,
                style: ReadingTypography.reflection(
                  color: OraclyChrome.cream.withValues(alpha: 0.88),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
