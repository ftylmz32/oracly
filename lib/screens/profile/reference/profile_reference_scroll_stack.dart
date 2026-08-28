/// Scroll stack — memory first, utility last. Real data only.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/resilience_copy.dart';
import '../../../core/experience/providers/continue_where_you_left_off_provider.dart';
import '../../../core/experience/widgets/continue_where_you_left_off_button.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../shared/widgets/oracly_skeleton_loader.dart';
import 'profile_journal_compact.dart';
import 'profile_moments_strip.dart';
import 'profile_my_story_entry.dart';
import 'profile_reference_divider.dart';
import 'profile_reference_new_user_empty_state.dart';
import 'profile_reference_or_observation_card.dart';
import 'profile_reference_premium_gems_section.dart';
import 'profile_reference_quick_actions_grid.dart';
import 'profile_reference_tokens.dart';
import 'profile_soulmate_entry_row.dart';

class ProfileReferenceScrollStack extends StatelessWidget {
  const ProfileReferenceScrollStack({
    super.key,
    required this.hasHistory,
    required this.discoveryLoading,
    this.resumeTarget,
  });

  final bool hasHistory;
  final bool discoveryLoading;
  final ContinueWhereYouLeftOffTarget? resumeTarget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resumeTarget != null) ...[
          ContinueWhereYouLeftOffButton(target: resumeTarget!),
          SizedBox(height: ProfileReferenceTokens.afterHighlight),
        ],
        if (discoveryLoading)
          OraclySkeletonLoader(
            message: ResilienceCopy.profileLoading,
            lines: 5,
          )
        else if (!hasHistory) ...[
          ProfileReferenceNewUserEmptyState(
            onDaily: () =>
                OraclyNavigationService.startDailyCardDraw(context),
            onOr: () => OraclyNavigationService.openChat(context),
            onFirstDiscovery: () =>
                OraclyNavigationService.openCoffee(context),
          ),
          SizedBox(height: ProfileReferenceTokens.afterStory),
          const ProfileMomentsStrip(),
          SizedBox(height: ProfileReferenceTokens.withinUtility),
          const ProfileJournalCompact(),
          SizedBox(height: ProfileReferenceTokens.afterStory),
          ProfileReferenceQuickActionsGrid(
            includeJournal: false,
            onOpenSettings: () => OraclyNavigationService.openSettings(context),
          ),
        ] else ...[
          const ProfileMyStoryEntry(),
          SizedBox(height: ProfileReferenceTokens.afterHighlight),
          const ProfileMomentsStrip(),
          SizedBox(height: ProfileReferenceTokens.withinUtility),
          const ProfileJournalCompact(),
          SizedBox(height: ProfileReferenceTokens.afterHighlight),
          const ProfileReferenceOrObservationCard(),
          const ProfileReferenceDivider(),
          const ProfileSoulMateEntryRow(),
          SizedBox(height: ProfileReferenceTokens.afterStory),
          ProfileReferenceQuickActionsGrid(
            includeJournal: false,
            onOpenSettings: () => OraclyNavigationService.openSettings(context),
          ),
          SizedBox(height: ProfileReferenceTokens.beforePremium),
          const ProfileReferencePremiumGemsSection(),
        ],
      ],
    );
  }
}
