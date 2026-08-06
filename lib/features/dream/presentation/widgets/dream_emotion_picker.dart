/// SPRINT-001 — Emotion selection chips.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../copy/dream_copy.dart';
import '../../models/dream_emotion.dart';
import 'dream_section_header.dart';

class DreamEmotionPicker extends StatelessWidget {
  const DreamEmotionPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<DreamEmotionId> selected;
  final ValueChanged<DreamEmotionId> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DreamCopy.emotionsLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final emotion in DreamEmotionId.values)
              DreamChip(
                label: emotion.labelTr,
                selected: selected.contains(emotion),
                onTap: () => onToggle(emotion),
              ),
          ],
        ),
      ],
    );
  }
}
