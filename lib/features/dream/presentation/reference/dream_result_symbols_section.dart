/// Symbol rows for dream result.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/dream_copy.dart';
import '../../services/dream_reading_presentation.dart';
import 'dream_result_premium_card.dart';

class DreamResultSymbolsSection extends StatelessWidget {
  const DreamResultSymbolsSection({super.key, required this.rows});

  final List<DreamSymbolRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return DreamResultPremiumCard(
      title: DreamCopy.resultSymbolsTitle,
      body: '',
      icon: Icons.diamond_outlined,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.sm),
            _SymbolRow(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _SymbolRow extends StatelessWidget {
  const _SymbolRow({required this.row});

  final DreamSymbolRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: OraclyChrome.violet.withValues(alpha: 0.18),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(
            Icons.auto_awesome_outlined,
            size: 16,
            color: OraclyChrome.goldLight.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: ReadingTypography.bodySmall(
                  color: OraclyChrome.cream.withValues(alpha: 0.92),
                ),
              ),
              if (row.meaning.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  row.meaning,
                  style: ReadingTypography.footnote(
                    color: OraclyChrome.cream.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
