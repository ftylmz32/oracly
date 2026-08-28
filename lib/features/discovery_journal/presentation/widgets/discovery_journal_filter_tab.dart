/// Underline filter tab — shared journal chip chrome.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class DiscoveryJournalFilterTab extends StatelessWidget {
  const DiscoveryJournalFilterTab({
    super.key,
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
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: OraclyChrome.gold.withValues(
                    alpha: selected ? 0.82 : 0.18,
                  ),
                  width: selected ? 1.2 : 0.6,
                ),
              ),
            ),
            child: Text(
              label,
              style: ReadingTypography.sectionLabel(
                color: selected
                    ? OraclyChrome.goldLight
                    : OraclyChrome.cream.withValues(alpha: 0.48),
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
