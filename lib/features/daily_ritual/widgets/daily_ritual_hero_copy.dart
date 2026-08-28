/// Daily ritual copy — ritual time + real guidance, never a score.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../home/reference/home_reference_hero_detail_button.dart';
import '../services/daily_ritual_reflections.dart';

class DailyRitualHeroCopy extends StatelessWidget {
  const DailyRitualHeroCopy({
    super.key,
    required this.universe,
    required this.body,
    required this.energySize,
    required this.cardDrawn,
    required this.onDraw,
    required this.compact,
  });

  final OraclyUniverseState universe;
  final String body;
  /// Layout typography budget from Home viewport (not an energy metric).
  final double energySize;
  final bool cardDrawn;
  final VoidCallback? onDraw;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final titleSize = (energySize / scale.clamp(1.0, 1.4)).clamp(22.0, 32.0);
    final cta = OraclyL10n.t('home.today_continue');
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DailyRitualReflections.ritualLabel(universe),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.pageTitle(
                    color: AppColors.goldLight.withValues(alpha: 0.98),
                  ).copyWith(
                    fontSize: compact ? titleSize - 2 : titleSize,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Text(
                  body,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.bodySmall(
                    color: AppColors.ivory.withValues(alpha: 0.92),
                  ).copyWith(
                    height: 1.34,
                    letterSpacing: CraftsmanshipRhythm.bodyLetterSpacing,
                    fontSize: compact ? 12 : 13.5,
                  ),
                ),
                SizedBox(height: compact ? 7 : 9),
                HomeReferenceHeroDetailButton(
                  label: cta,
                  onPressed: onDraw,
                  compact: compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
