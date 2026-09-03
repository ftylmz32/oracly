/// Production Home body — cinematic preferred sizes; natural scroll when needed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/experience/providers/continue_where_you_left_off_provider.dart';
import '../../../core/experience/widgets/continue_where_you_left_off_button.dart';
import '../reference/home_reference_scope.dart';
import 'home_master_bottom_inset.dart';
import 'home_master_composition.dart';
import 'home_master_grid.dart';
import 'home_master_header.dart';
import 'home_master_hero.dart';
import 'home_master_or.dart';
import 'home_master_premium.dart';
import 'home_master_reveal.dart';
import 'home_master_today.dart';
import 'home_oracle_next_action_card.dart';

/// Sections: header / hero / OR / Bugünün İzi / 3×2+Dream / premium.
class HomeMasterBody extends ConsumerWidget {
  const HomeMasterBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeTarget = ref.watch(
      continueWhereYouLeftOffProvider.select((async) => async.valueOrNull),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final bottomInset = HomeMasterBottomInset.resolve(context);
        final composition = HomeMasterComposition.resolve(
          bodyHeight: constraints.maxHeight,
          navClearance: bottomInset,
          screenHeightHint: media.size.height,
          textScale: media.textScaler.scale(1),
        );
        final layout = composition.layout;

        final column = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: layout.headerHeight,
              child: const HomeMasterReveal(
                index: 0,
                child: HomeMasterHeader(),
              ),
            ),
            SizedBox(height: layout.greetingToHero),
            SizedBox(
              height: layout.heroSlotHeight,
              child: HomeMasterReveal(
                index: 1,
                child: HomeMasterHero(height: layout.heroSlotHeight),
              ),
            ),
            SizedBox(height: layout.heroToOr),
            SizedBox(
              height: layout.orGuideHeight,
              child: HomeMasterReveal(
                index: 2,
                child: HomeMasterOr(height: layout.orGuideHeight),
              ),
            ),
            SizedBox(height: layout.orToToday),
            HomeMasterReveal(
              index: 3,
              child: HomeMasterToday(height: layout.todayMomentHeight),
            ),
            if (resumeTarget != null) ...[
              const SizedBox(height: 10),
              Center(
                child: ContinueWhereYouLeftOffButton(target: resumeTarget),
              ),
            ],
            const HomeOracleNextActionCard(),
            SizedBox(height: layout.heroToModules),
            HomeMasterReveal(
              index: 4,
              child: HomeMasterGrid(layout: layout),
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
        );

        return HomeReferenceScope(
          layout: layout,
          child: composition.requiresScroll
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: column,
                )
              : Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: column,
                ),
        );
      },
    );
  }
}
