/// Prominent observational story — real recurring themes only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../personal_discovery/models/cross_discovery_insight.dart';
import '../../../personal_discovery/models/oracly_observation.dart';
import '../../../personal_discovery/presentation/widgets/oracly_observation_surface.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../copy/discovery_journal_copy.dart';
import 'discovery_archive_heading.dart';
import 'discovery_journal_observation.dart';
import 'discovery_journal_theme_card.dart';

class DiscoveryJournalStory extends ConsumerWidget {
  const DiscoveryJournalStory({super.key, this.focusTheme});

  final String? focusTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(personalDiscoveryProfileProvider).valueOrNull;
    final themes = [
      for (final i in discovery?.crossInsights ??
          const <CrossDiscoveryInsight>[])
        if (i.isRecurring) i,
    ].take(4).toList();
    final focus = focusTheme?.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoveryArchiveHeading(
          label: DiscoveryJournalCopy.crossTitle,
          top: 0,
        ),
        OraclyGlassCard(
          premium: true,
          borderRadius: OraclyChrome.heroRadius,
          glowStrength: 0.78,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (themes.isNotEmpty)
                Text(
                  DiscoveryJournalCopy.story(
                    [for (final theme in themes) theme.theme],
                  ),
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
                  ),
                )
              else
                Text(
                  DiscoveryJournalCopy.storyNone,
                  style: ReadingTypography.body(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
                  ),
                ),
              if (themes.isNotEmpty)
                for (final theme in themes)
                  DiscoveryJournalThemeCard(
                    insight: theme,
                    focused: focus != null &&
                        focus == theme.theme.trim().toLowerCase(),
                  ),
              OraclyObservationSurface(
                surface: 'journal',
                builder: (context, OraclyObservation? observation) {
                  if (observation == null) return const SizedBox.shrink();
                  return DiscoveryJournalObservation(observation: observation);
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                DiscoveryJournalCopy.philosophy,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.cream.withValues(alpha: 0.52),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
