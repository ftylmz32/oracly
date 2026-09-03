/// Bugünün İzi — honest daily guidance (ritual + observation), no scores.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../daily_ritual/widgets/daily_ritual_card.dart';
import '../widgets/home_daily_message_teaser.dart';
import 'home_reference_scope.dart';

/// Section wrapper around the real daily ritual card.
///
/// [height] is the **card** height; the section label sits above it.
class HomeTodayTrace extends StatelessWidget {
  const HomeTodayTrace({super.key, this.height});

  final double? height;

  static String get label => OraclyL10n.t('home.today_moment');

  @override
  Widget build(BuildContext context) {
    final layout = HomeReferenceScope.maybeOf(context);
    final cardH = height ?? layout?.todayMomentHeight ?? 122;

    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBound = constraints.maxHeight.isFinite;
          final labelH = 22.0;
          final gap = 8.0;
          final cardBudget = hasBound
              ? (constraints.maxHeight - labelH - gap).clamp(48.0, cardH)
              : cardH;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: labelH,
                child: OraclyA11y.chromeTextScale(
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              ReadingTypography.eyebrow(
                                color: OraclyA11y.goldReadable(
                                  OraclyChrome.goldLight,
                                ),
                                fontSize: 12,
                              ).copyWith(
                                letterSpacing:
                                    CraftsmanshipRhythm.sectionLabelTracking +
                                        0.2,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                OraclyChrome.gold.withValues(alpha: 0.28),
                                OraclyChrome.gold.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          child: const SizedBox(height: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: gap),
              SizedBox(height: cardBudget, child: const DailyRitualCard()),
              if (!hasBound) const HomeDailyMessageTeaser(),
            ],
          );
        },
      ),
    );
  }
}
