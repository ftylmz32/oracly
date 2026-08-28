/// Keşif Karşılaştırma — two real discoveries, one honest synthesis.
library;

import 'package:flutter/material.dart';

import '../../../design_system/app_layout.dart';
import '../../../design_system/oracly_app_bar.dart';
import '../../../design_system/oracly_chrome.dart';
import '../../../theme/app_spacing.dart';
import '../../../../features/discovery_journal/presentation/widgets/discovery_journal_atmosphere.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/discovery_comparison_copy.dart';
import '../../models/discovery_comparison_result.dart';
import '../widgets/discovery_comparison_body.dart';

class DiscoveryComparisonScreen extends StatelessWidget {
  const DiscoveryComparisonScreen({super.key, required this.result});

  final DiscoveryComparisonResult result;

  @override
  Widget build(BuildContext context) {
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
                title: DiscoveryComparisonCopy.title,
                titleIcon: Icons.compare_arrows_rounded,
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  OraclyChrome.screenSide,
                  AppSpacing.lg,
                  OraclyChrome.screenSide,
                  AppLayout.scrollBottomInset(context),
                ),
                children: [
                  DiscoveryComparisonBody(result: result),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
