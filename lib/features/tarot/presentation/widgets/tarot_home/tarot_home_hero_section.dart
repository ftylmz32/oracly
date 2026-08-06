/// OR-1010 / OR-407 — Tarot home hero: title, subtitle, sacred orb centerpiece.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../oracle_presence/oracle_presence_venue.dart';
import '../../../../oracle_presence/widgets/oracle_whisper_line.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'oracly_sacred_identity.dart';
import 'tarot_atmosphere.dart';
import 'tarot_home_orb_ambience.dart';
import 'tarot_home_progressive_discovery.dart';

/// Top sacred focal section — orb as centerpiece, refined typography.
class TarotHomeHeroSection extends StatelessWidget {
  const TarotHomeHeroSection({super.key});

  static const String _title = 'TAROT';
  static const String _subtitle = 'Evrenin rehberliğinde kartlarını seç.';

  @override
  Widget build(BuildContext context) {
    final phase = TarotHomeScrollScope.maybeOf(context)?.ambientPhase ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 240,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: TarotAtmosphere.heroOrbChamberGlow(phase),
              ),
            ),
          ),
        ),
        Column(
          children: [
            const TarotHomeOrbAmbience(),
            SizedBox(height: OraclyRhythm.heroOrbToTitle),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: OraclyTypography.heroTitleShader,
              child: Text(
                _title,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                  height: 1.05,
                ),
              ),
            ),
            SizedBox(height: OraclyRhythm.heroTitleToSubtitle),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: OraclyRhythm.heroSubtitleInset),
              child: Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: OraclyTypography.bodyWhisper(alpha: 0.76),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            const OracleWhisperLine(venue: OraclePresenceVenue.tarot),
          ],
        ),
      ],
    );
  }
}
