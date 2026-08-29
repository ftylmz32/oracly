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
    final labelBottom = 8.0;

    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2, right: 2, bottom: labelBottom),
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
                                CraftsmanshipRhythm.sectionLabelTracking + 0.2,
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
          SizedBox(height: cardH, child: const DailyRitualCard()),
          const HomeDailyMessageTeaser(),
        ],
      ),
    );
  }
}
