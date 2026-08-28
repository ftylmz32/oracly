/// Mücevherler — live balance, honest economy, no fake shop.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import 'gems_reference_app_bar.dart';
import 'gems_reference_atmosphere.dart';
import 'gems_reference_cards.dart';
import 'gems_reference_daily_card.dart';
import 'gems_reference_economy.dart';
import 'gems_reference_explain.dart';
import 'gems_reference_hero.dart';
import 'gems_reference_tokens.dart';

class GemsReferenceScreen extends StatelessWidget {
  const GemsReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const GemsReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                GemsReferenceTokens.screenHorizontal,
                GemsReferenceTokens.screenTop,
                GemsReferenceTokens.screenHorizontal,
                0,
              ),
              child: GemsReferenceAppBar(
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  GemsReferenceTokens.screenHorizontal,
                  GemsReferenceTokens.headerToHero,
                  GemsReferenceTokens.screenHorizontal,
                  GemsReferenceTokens.scrollBottomInset(context),
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.maxContentWidth,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GemsBalanceHero(),
                          SizedBox(height: GemsReferenceTokens.sectionGap),
                          GemsEconomySection(),
                          SizedBox(height: GemsReferenceTokens.sectionGap),
                          GemsExplainSection(),
                          SizedBox(height: GemsReferenceTokens.sectionGap),
                          GemsDailyRewardCard(),
                          SizedBox(height: GemsReferenceTokens.sectionGap),
                          GemsHistoryCard(),
                          SizedBox(height: GemsReferenceTokens.sectionGap),
                          GemsHonestyNote(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
