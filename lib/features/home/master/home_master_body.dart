/// Production Home body — natural vertical scroll (reference-aligned).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/experience/providers/continue_where_you_left_off_provider.dart';
import '../../../core/experience/widgets/continue_where_you_left_off_button.dart';
import '../reference/home_reference_scope.dart';
import '../reference/home_reference_tokens.dart';
import 'home_master_grid.dart';
import 'home_master_header.dart';
import 'home_master_hero.dart';
import 'home_master_or.dart';
import 'home_master_premium.dart';
import 'home_master_reveal.dart';
import 'home_master_today.dart';
import 'home_oracle_next_action_card.dart';

/// Sections: header / hero / OR / Bugünün İzi / 3×2 / premium.
class HomeMasterBody extends ConsumerWidget {
  const HomeMasterBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeTarget = ref.watch(
      continueWhereYouLeftOffProvider.select((async) => async.valueOrNull),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = AppLayout.scrollBottomInset(context);
        final hintH = MediaQuery.sizeOf(context).height;
        final layout = HomeReferenceTokens.layoutFor(hintH);

        return HomeReferenceScope(
          layout: layout,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: layout.headerHeight,
                  child: const HomeMasterReveal(
                    index: 0,
                    child: HomeMasterHeader(),
                  ),
                ),
                SizedBox(height: layout.greetingToHero),
                HomeMasterReveal(
                  index: 1,
                  child: HomeMasterHero(height: layout.heroSlotHeight),
                ),
                SizedBox(height: layout.heroToOr),
                HomeMasterReveal(
                  index: 2,
                  child: HomeMasterOr(height: layout.orGuideHeight),
                ),
                SizedBox(height: layout.orToToday),
                HomeMasterReveal(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HomeMasterToday(height: layout.todayMomentHeight),
                      if (resumeTarget != null) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: ContinueWhereYouLeftOffButton(
                            target: resumeTarget,
                          ),
                        ),
                      ],
                      const HomeOracleNextActionCard(),
                    ],
                  ),
                ),
                SizedBox(height: layout.heroToModules),
                const HomeMasterReveal(
                  index: 4,
                  child: HomeMasterGrid(),
                ),
                SizedBox(height: layout.modulesToPremium),
                SizedBox(
                  height: layout.premiumHeight,
                  child: const HomeMasterReveal(
                    index: 5,
                    child: HomeMasterPremium(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
