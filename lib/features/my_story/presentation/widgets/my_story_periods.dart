/// Time chapters — 7 / 30 / 90 gün only when data supports them.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../discovery_journal/copy/discovery_journal_over_time_copy.dart';
import '../../../discovery_journal/presentation/widgets/discovery_archive_heading.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_spine.dart';
import '../../../personal_discovery/models/theme_over_time_period.dart';
import '../../copy/my_story_copy.dart';
import '../../models/personal_story.dart';

class MyStoryPeriods extends StatefulWidget {
  const MyStoryPeriods({super.key, required this.periods});

  final List<PersonalStoryPeriod> periods;

  @override
  State<MyStoryPeriods> createState() => _MyStoryPeriodsState();
}

class _MyStoryPeriodsState extends State<MyStoryPeriods> {
  ThemeOverTimePeriod? _selected;

  @override
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) return const SizedBox.shrink();
    final active = _selected ?? widget.periods.first.period;
    final chapter = widget.periods.firstWhere(
      (item) => item.period == active,
      orElse: () => widget.periods.first,
    );
    final idx = widget.periods.indexOf(chapter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoveryArchiveHeading(
          label: MyStoryCopy.periodHeading,
          top: AppSpacing.s16,
        ),
        OraclyGlassCard(
          premium: true,
          borderRadius: OraclyChrome.heroRadius,
          glowStrength: 0.70,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final item in widget.periods)
                    _PeriodTab(
                      label: DiscoveryJournalOverTimeCopy.periodLabel(
                        item.period,
                      ),
                      selected: item.period == chapter.period,
                      onTap: () => setState(() => _selected = item.period),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              DiscoveryJournalSpine(
                isFirst: idx <= 0,
                isLast: idx >= widget.periods.length - 1,
                child: Text(
                  chapter.narrative,
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.82),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
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
