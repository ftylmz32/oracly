/// BENİM HİKÂYEM — evolving narrative from real discoveries.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_atmosphere.dart';
import '../../../personal_discovery/models/personal_discovery_profile.dart';
import '../../../personal_discovery/providers/personal_discovery_providers.dart';
import '../../../../shared/widgets/oracly_cinematic_loading.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/my_story_copy.dart';
import '../../models/personal_story.dart';
import '../../services/personal_story_composer.dart';
import '../widgets/my_story_narrative.dart';
import '../widgets/my_story_periods.dart';

class MyStoryScreen extends ConsumerWidget {
  const MyStoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(personalDiscoveryProfileProvider);
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const DiscoveryJournalAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                OraclyChrome.screenSide,
                OraclyChrome.screenTop,
                OraclyChrome.screenSide,
                0,
              ),
              child: OraclyAppBar(
                title: MyStoryCopy.title,
                titleIcon: Icons.menu_book_rounded,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                OraclyChrome.screenSide,
                AppSpacing.s8,
                OraclyChrome.screenSide,
                0,
              ),
              child: Text(
                MyStoryCopy.subtitle,
                textAlign: TextAlign.center,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.62),
                ),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const OraclyCinematicLoading(compact: true),
                error: (_, _) => _StoryScroll(
                  story: PersonalStoryComposer.compose(
                    PersonalDiscoveryProfile.empty,
                  ),
                ),
                data: (profile) => _StoryScroll(
                  story: PersonalStoryComposer.compose(profile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryScroll extends StatelessWidget {
  const _StoryScroll({required this.story});

  final PersonalStory story;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        OraclyChrome.screenSide,
        AppSpacing.lg,
        OraclyChrome.screenSide,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        MyStoryNarrative(story: story),
        MyStoryPeriods(periods: story.periods),
      ],
    );
  }
}
