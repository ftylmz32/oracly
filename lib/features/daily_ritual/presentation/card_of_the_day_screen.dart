/// Card of the Day result — symbolic guidance, OR, optional save.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/oracly_app_bar.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_adaptive_scroll_view.dart';
import '../../../shared/widgets/oracly_scaffold.dart';
import '../../ai/oracle_conversation/widgets/or_ask_button.dart';
import '../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../tarot/presentation/destem/destem_card_art.dart';
import '../../tarot/deck/oracly_tarot_bridge.dart';
import '../copy/card_of_the_day_copy.dart';
import '../models/card_of_the_day.dart';
import '../services/card_of_the_day_bindings.dart';

class CardOfTheDayScreen extends StatelessWidget {
  const CardOfTheDayScreen({super.key, required this.card});

  final CardOfTheDay card;

  @override
  Widget build(BuildContext context) {
    final data = OraclyTarotBridge.byRitualId(card.ritualId);
    final name = CardOfTheDayBindings.nameOf(card);
    final meaning = CardOfTheDayBindings.meaningOf(card);
    return OraclyScaffold(
      safeArea: false,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            OraclyChrome.screenSide,
            OraclyChrome.screenTop,
            OraclyChrome.screenSide,
            AppLayout.scrollBottomInset(context),
          ),
          child: Column(
            children: [
              OraclyAppBar(
                title: CardOfTheDayCopy.title,
                titleIcon: Icons.wb_twilight_outlined,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: OraclyAdaptiveScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.s12),
                      if (data != null)
                        Center(
                          child: DestemCardArt(
                            card: data,
                            width: 160,
                          ),
                        ),
                      SizedBox(height: AppSpacing.s12),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: OraclyChrome.engravedTitle(size: 22),
                      ),
                      SizedBox(height: AppSpacing.s16),
                      Text(
                        CardOfTheDayCopy.guidanceLabel,
                        style: ReadingTypography.sectionLabel(
                          color: OraclyChrome.goldLight.withValues(alpha: 0.86),
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: AppSpacing.s8),
                      Text(
                        meaning,
                        style: ReadingTypography.body(
                          color: OraclyChrome.cream.withValues(alpha: 0.88),
                        ),
                      ),
                      SizedBox(height: AppSpacing.s12),
                      Text(
                        CardOfTheDayCopy.honesty,
                        style: ReadingTypography.footnote(
                          color: OraclyChrome.cream.withValues(alpha: 0.52),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      OrAskButton(
                        readingContext:
                            CardOfTheDayBindings.oracleContext(card),
                        label: CardOfTheDayCopy.orOpen,
                      ),
                      SizedBox(height: AppSpacing.s8),
                      SaveFavoriteMomentLink(
                        draft: CardOfTheDayBindings.favoriteDraft(card),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
