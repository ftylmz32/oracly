/// Animated energy percentage — quiet gold breath for hero card.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/oracly_quiet_motion.dart';

class HomeReferenceEnergyPercent extends StatefulWidget {
  const HomeReferenceEnergyPercent({
    super.key,
    required this.percent,
    this.textAlign = TextAlign.center,
  });

  final int percent;
  final TextAlign textAlign;

  @override
  State<HomeReferenceEnergyPercent> createState() =>
      _HomeReferenceEnergyPercentState();
}

class _HomeReferenceEnergyPercentState extends State<HomeReferenceEnergyPercent>
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
      builder: (context, child) {
        final t = still
            ? 0.4
            : Curves.easeInOut.transform(_breath.value.clamp(0.0, 1.0));
        final glowAlpha = 0.10 + t * 0.08;
        final blur = 14.0 + t * 6;

        return Stack(
          alignment: widget.textAlign == TextAlign.start
              ? Alignment.centerLeft
              : Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1.0 + t * 0.018,
              alignment: widget.textAlign == TextAlign.start
                  ? Alignment.centerLeft
                  : Alignment.center,
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
            child!,
          ],
        );
      },
      child: Text(
        '${widget.percent}%',
        textAlign: widget.textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.hero.copyWith(
          color: AppColors.gold.withValues(alpha: 0.96),
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: AppColors.goldGlow.withValues(alpha: 0.28),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}
