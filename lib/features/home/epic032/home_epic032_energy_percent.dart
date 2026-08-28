/// EPIC-032 — Animated energy percentage for hero card.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import 'home_epic032_spec.dart';

class HomeEpic032EnergyPercent extends StatefulWidget {
  const HomeEpic032EnergyPercent({
    super.key,
    required this.percent,
    this.textAlign = TextAlign.start,
  });

  final int percent;
  final TextAlign textAlign;

  @override
  State<HomeEpic032EnergyPercent> createState() =>
      _HomeEpic032EnergyPercentState();
}

class _HomeEpic032EnergyPercentState extends State<HomeEpic032EnergyPercent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.4);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = still
            ? 0.4
            : Curves.easeInOut.transform(_breath.value.clamp(0.0, 1.0));
        final glowAlpha = 0.10 + t * 0.08;
        final blur = HomeEpic032Spec.starGlowBlur * 0.7 + t * 6;
        final align = widget.textAlign == TextAlign.start
            ? Alignment.centerLeft
            : Alignment.center;

        return Stack(
          alignment: align,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1.0 + t * 0.018,
              alignment: align,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldGlow.withValues(alpha: glowAlpha),
                      blurRadius: blur,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: AppColors.purpleGlow
                          .withValues(alpha: 0.06 + t * 0.04),
                      blurRadius: blur * 1.3,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const SizedBox(width: 72, height: 72),
              ),
            ),
            Text(
              '${widget.percent}%',
              textAlign: widget.textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.hero.copyWith(
                fontSize: HomeEpic032Spec.heroPercentSize,
                height: 0.92,
                fontWeight: FontWeight.w200,
                letterSpacing: -2.4,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: AppColors.gold.withValues(alpha: 0.96),
                shadows: [
                  Shadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.28),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
