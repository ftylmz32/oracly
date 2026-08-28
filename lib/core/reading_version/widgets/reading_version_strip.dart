/// Version picker — original, revisions, compare. One reading row in journal.
library;

import 'package:flutter/material.dart';

import '../../design_system/oracly_chrome.dart';
import '../../theme/app_spacing.dart';
import '../../theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../copy/reading_version_copy.dart';
import '../models/reading_version_group.dart';

class ReadingVersionStrip extends StatelessWidget {
  const ReadingVersionStrip({
    super.key,
    required this.group,
    required this.onSelect,
    this.onCompare,
  });

  final ReadingVersionGroup group;
  final ValueChanged<int> onSelect;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    if (!group.hasRevisions) return const SizedBox.shrink();
    final showNewBadge = group.viewingLatest && group.activeNumber > 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showNewBadge)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Text(
                ReadingVersionCopy.newReading,
                textAlign: TextAlign.center,
                style: ReadingTypography.sectionLabel(
                  color: OraclyChrome.goldLight,
                  fontSize: 11,
                ),
              ),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in group.entries)
                _Chip(
                  label: entry.isOriginal
                      ? ReadingVersionCopy.original
                      : ReadingVersionCopy.revision(entry.number),
                  selected: entry.number == group.activeNumber,
                  onTap: () => onSelect(entry.number),
                ),
            ],
          ),
          if (onCompare != null) ...[
            const SizedBox(height: AppSpacing.s8),
            OraclyPressable(
              onTap: onCompare,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Center(
                  child: Text(
                    ReadingVersionCopy.compare,
                    style: ReadingTypography.footnote(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: selected ? 0.82 : 0.28),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: ReadingTypography.footnote(
                color: selected
                    ? OraclyChrome.goldLight
                    : OraclyChrome.cream.withValues(alpha: 0.62),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
