/// Premium hero badge + blended crown art helpers.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/hero_art/hero_art_painters.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Painted crown with soft radial fade — no opaque square bitmap.
class PremiumReferenceBlendedCrown extends StatelessWidget {
  const PremiumReferenceBlendedCrown({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          return RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 0.72,
            colors: const [
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: const [0.0, 0.62, 1.0],
          ).createShader(bounds);
        },
        child: CustomPaint(
          size: Size(size, size),
          painter: const PremiumArtworkPainter(phase: 0.55),
        ),
      ),
    );
  }
}

class PremiumReferenceBadge extends StatelessWidget {
  const PremiumReferenceBadge({super.key, this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [AppColors.goldLight, AppColors.gold],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.24),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          active
              ? OraclyL10n.t('premium.status_active_label')
              : OraclyL10n.t('premium.status_premium_label'),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.purpleDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
