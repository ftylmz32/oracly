/// SPRINT-003 — Reflective conversation starters.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../ai/presentation/widgets/suggestion_chip.dart';

class CompanionSuggestionChips extends StatelessWidget {
  const CompanionSuggestionChips({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSpacing.screenHorizontal.copyWith(bottom: AppSpacing.sm),
      child: Row(
        children: [
          for (final suggestion in suggestions) ...[
            SuggestionChip(
              label: suggestion,
              onTap: () => onSelected(suggestion),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
