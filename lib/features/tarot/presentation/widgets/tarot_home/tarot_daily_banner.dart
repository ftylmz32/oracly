/// OR-402 / OR-410 — Daily Tarot premium crystal banner.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'oracly_sacred_identity.dart';
import 'tarot_home_section_primitives.dart';

/// Sacred daily card invitation — crystal glass ritual banner.
class TarotDailyBanner extends StatelessWidget {
  const TarotDailyBanner({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  static const String _title = 'Günlük Tarot';
  static const String _subtitle =
      'Bugün kartın sana rehberlik etmeye hazır. Tek dokunuşla günün mesajını al.';
  static const String _cta = 'Günün Kartını Çek';

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: TarotHomeSectionShell(
        lightTier: OraclyLightTier.lowerChamber,
        showOrnaments: false,
        showStars: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title.toUpperCase(),
                    style: OraclyTypography.sectionLabel(fontSize: 11.5),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    _subtitle,
                    style: OraclyTypography.bodyWhisper(fontSize: 12.5, alpha: 0.82),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: OraclyRhythm.sectionContentGap),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: OraclySacredPalette.champagneDeep.withValues(alpha: 0.72),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        _cta,
                        style: OraclyTypography.tileTitle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: OraclyRhythm.sectionContentGap),
            const TarotHomeMysticIcon(
              icon: Icons.nightlight_round,
              size: 64,
              iconSize: 30,
            ),
          ],
        ),
      ),
    );
  }
}
