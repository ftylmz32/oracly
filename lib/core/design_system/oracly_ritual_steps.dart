/// Compact 3-step ritual list — coffee, palm, and similar chambers.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'oracly_chrome.dart';

class OraclyRitualSteps extends StatelessWidget {
  const OraclyRitualSteps({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _StepRow(index: i + 1, label: steps[i]),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$index',
            textAlign: TextAlign.center,
            style: OraclyChrome.sectionLabel(size: 11).copyWith(
              color: OraclyChrome.goldLight.withValues(alpha: 0.92),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.90),
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
