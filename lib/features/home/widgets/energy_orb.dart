import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class EnergyOrb extends StatefulWidget {
  final int energy;

  const EnergyOrb({
    super.key,
    required this.energy,
  });

  @override
  State<EnergyOrb> createState() => _EnergyOrbState();
}

class _EnergyOrbState extends State<EnergyOrb>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _ringController;
  late final Animation<double> _scale;
  late final Animation<double> _ringValue;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: .99, end: 1.015).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringValue = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _ringController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 168.0;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: .12),
              blurRadius: 36,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: AppColors.accent.withValues(alpha: .08),
              blurRadius: 48,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _ringValue,
              builder: (context, _) {
                return SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: _ringValue.value *
                        (widget.energy / 100),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor:
                        AppColors.surfaceLight.withValues(
                      alpha: .55,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.gold.withValues(alpha: .85),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.orbCore.withValues(alpha: .35),
                    AppColors.accent.withValues(alpha: .22),
                    AppColors.surfaceDark,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .12),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.energy}',
                  style: AppTextStyles.hero.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Text(
                  'enerji',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
