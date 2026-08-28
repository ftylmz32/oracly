/// My Story preview — golden timeline of real periods only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/discovery_journal/copy/discovery_journal_over_time_copy.dart';
import '../../../features/my_story/copy/my_story_copy.dart';
import '../../../features/my_story/models/personal_story.dart';
import '../../../features/my_story/services/personal_story_composer.dart';
import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../../../features/personal_discovery/providers/personal_discovery_providers.dart';
import 'profile_chamber_chrome.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileMyStoryEntry extends ConsumerWidget {
  const ProfileMyStoryEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discovery = ref.watch(personalDiscoveryProfileProvider).valueOrNull;
    final story = PersonalStoryComposer.compose(
      discovery ?? PersonalDiscoveryProfile.empty,
    );

    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.story,
      glowStrength: 0.92,
      onTap: () => OraclyNavigationService.openMyStory(context),
      child: ProfileChamberRail(
        emphasis: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileChamberTitle(title: MyStoryCopy.title, emphasis: true),
            SizedBox(height: ProfileChamberGap.afterTitle),
            Text(
              story.narrative,
              softWrap: true,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.88),
              ),
            ),
            if (story.periods.isNotEmpty) ...[
              SizedBox(height: AppSpacing.s12),
              _Timeline(periods: story.periods.take(3).toList()),
            ],
            SizedBox(height: ProfileChamberGap.beforeCta),
            ProfileChamberCta(label: MyStoryCopy.openCta),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.periods});

  final List<PersonalStoryPeriod> periods;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < periods.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: ColoredBox(
                color: OraclyChrome.gold.withValues(alpha: 0.28),
                child: const SizedBox(width: 1, height: 10),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.85),
                  ),
                  child: const SizedBox(width: 7, height: 7),
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  DiscoveryJournalOverTimeCopy.periodLabel(periods[i].period),
                  softWrap: true,
                  style: ReadingTypography.bodyCore(
                    color: OraclyChrome.cream.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
