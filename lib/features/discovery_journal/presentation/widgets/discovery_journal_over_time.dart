/// ZAMAN İÇİNDE — real theme evolution, only when records support it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../personal_discovery/models/theme_over_time_period.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../../personal_discovery/services/theme_over_time_builder.dart';
import '../../copy/discovery_journal_over_time_copy.dart';
import 'discovery_archive_heading.dart';
import 'discovery_journal_over_time_timeline.dart';

class DiscoveryJournalOverTime extends ConsumerStatefulWidget {
  const DiscoveryJournalOverTime({super.key});

  @override
  ConsumerState<DiscoveryJournalOverTime> createState() =>
      _DiscoveryJournalOverTimeState();
}

class _DiscoveryJournalOverTimeState
    extends ConsumerState<DiscoveryJournalOverTime> {
  ThemeOverTimePeriod? _selected;

  @override
  Widget build(BuildContext context) {
    final observations =
        ref.watch(personalDiscoveryProfileProvider).valueOrNull?.observations ??
            const [];
    final comparisons = ThemeOverTimeBuilder.fromObservations(observations);
    if (comparisons.isEmpty) return const SizedBox.shrink();

    final activePeriod = _selected ?? comparisons.first.period;
    final comparison = comparisons.firstWhere(
      (item) => item.period == activePeriod,
      orElse: () => comparisons.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoveryArchiveHeading(
          label: DiscoveryJournalOverTimeCopy.title,
          top: AppSpacing.s12,
        ),
        OraclyGlassCard(
          premium: true,
          borderRadius: OraclyChrome.heroRadius,
          glowStrength: 0.72,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final item in comparisons)
                    _PeriodTab(
                      label: DiscoveryJournalOverTimeCopy.periodLabel(
                        item.period,
                      ),
                      selected: item.period == comparison.period,
                      onTap: () => setState(() => _selected = item.period),
                    ),
                ],
              ),
              DiscoveryJournalOverTimeTimeline(comparison: comparison),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s12),
                child: Text(
                  DiscoveryJournalOverTimeCopy.narrative(comparison),
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
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
