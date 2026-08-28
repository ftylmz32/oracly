/// Real provider symbols as quiet gold pills — never invented names.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/reading_typography.dart';
import 'oracly_chrome.dart';
import 'oracly_soft_reveal.dart';

class ChamberSymbolPills extends StatelessWidget {
  const ChamberSymbolPills({
    super.key,
    required this.title,
    required this.labels,
    this.index = 0,
  });

  final String title;
  final List<String> labels;
  final int index;

  @override
  Widget build(BuildContext context) {
    final clean = labels.where((e) => e.trim().isNotEmpty).toList();
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: OraclySoftReveal(
        delay: Duration(milliseconds: 80 + index * 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.trim().isNotEmpty) ...[
              Text(
                title,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in clean) _pill(label),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OraclyChrome.gold.withValues(alpha: 0.48)),
        gradient: LinearGradient(
          colors: [
            OraclyChrome.gold.withValues(alpha: 0.16),
            OraclyChrome.violet.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w600,
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}
