/// Saved excerpt when the original history record was cleared.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_app_bar.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../../discovery_journal/presentation/widgets/discovery_journal_atmosphere.dart';
import '../../copy/favorite_moments_copy.dart';
import '../../models/favorite_moment.dart';
import '../widgets/favorite_moment_visual.dart';

class FavoriteMomentSnapshotScreen extends StatelessWidget {
  const FavoriteMomentSnapshotScreen({super.key, required this.moment});

  final FavoriteMoment moment;

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      safeArea: false,
      usePremiumBackground: false,
      backgroundOverlay: const DiscoveryJournalAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                OraclyChrome.screenSide,
                OraclyChrome.screenTop,
                OraclyChrome.screenSide,
                0,
              ),
              child: OraclyAppBar(
                title: FavoriteMomentsCopy.featureLabel(moment),
                onLeadingTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  OraclyChrome.screenSide,
                  AppSpacing.s16,
                  OraclyChrome.screenSide,
                  AppSpacing.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FavoriteMomentVisual(moment: moment, size: 96),
                    SizedBox(height: AppSpacing.s16),
                    Text(
                      moment.dateLabel,
                      style: ReadingTypography.sectionLabel(
                        color: OraclyChrome.cream.withValues(alpha: 0.58),
                      ),
                    ),
                    SizedBox(height: AppSpacing.s12),
                    Text(
                      FavoriteMomentsCopy.snapshotNotice,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.opening(
                        color: OraclyChrome.cream.withValues(alpha: 0.62),
                      ),
                    ),
                    SizedBox(height: AppSpacing.s20),
                    Text(
                      moment.quote,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.reflection(),
                    ),
                    if (moment.visualLabel?.trim().isNotEmpty ?? false) ...[
                      SizedBox(height: AppSpacing.s16),
                      Text(
                        moment.visualLabel!.trim(),
                        textAlign: TextAlign.center,
                        style: ReadingTypography.sectionLabel(
                          color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
