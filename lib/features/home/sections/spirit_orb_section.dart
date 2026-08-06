import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/living_spirit_orb.dart';

class SpiritOrbSection extends StatefulWidget {
  const SpiritOrbSection({super.key});

  @override
  State<SpiritOrbSection> createState() => _SpiritOrbSectionState();
}

class _SpiritOrbSectionState extends State<SpiritOrbSection> {
  double _breath = 0.5;

  @override
  Widget build(BuildContext context) {
    final spill = 0.04 + _breath * 0.06;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 40,
          child: IgnorePointer(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: spill),
                    AppColors.primary.withValues(alpha: spill * 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 120,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.gold.withValues(alpha: spill * 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        LivingSpiritOrb(
          size: 248,
          onBreath: (v) {
            if ((v - _breath).abs() > 0.02) setState(() => _breath = v);
          },
        ),
      ],
    );
  }
}
