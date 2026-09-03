/// Quick context chips for dream entry.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../models/dream_entry_context.dart';

class DreamEntryContextChips extends StatelessWidget {
  const DreamEntryContextChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<DreamEntryChipId> selected;
  final ValueChanged<DreamEntryChipId> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final chip in DreamEntryChipId.values)
          _Chip(
            label: DreamEntryContext.chipLabel(chip),
            icon: DreamEntryContext.chipIcon(chip),
            selected: selected.contains(chip),
            onTap: () => onToggle(chip),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? OraclyChrome.violet.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.18),
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: selected ? 0.42 : 0.16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: OraclyChrome.goldLight.withValues(alpha: 0.78)),
              const SizedBox(width: 6),
              Text(
                label,
                style: ReadingTypography.bodySmall(
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
