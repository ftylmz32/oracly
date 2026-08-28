/// Inner glass / velvet sheen — highlight wash and quiet gold bloom.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'oracly_surface_depth.dart';

class OraclyGlassCardSheen extends StatelessWidget {
  const OraclyGlassCardSheen({
    super.key,
    required this.child,
    required this.padding,
    required this.borderRadius,
    required this.premium,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool premium;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.ivory.withValues(
                      alpha: premium || selected ? 0.055 : 0.032,
                    ),
                    Colors.transparent,
                    AppColors.nearBlack.withValues(
                      alpha: premium ? 0.38 : 0.28,
                    ),
                  ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),
          if (premium || selected)
            Positioned(
              top: -30,
              right: -22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldGlow.withValues(
                        alpha: selected ? 0.14 : 0.10,
                      ),
                      blurRadius: 34,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const SizedBox(width: 76, height: 76),
              ),
            ),
          Padding(padding: padding, child: child),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(1.1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: OraclySurfaceDepth.innerVelvetRim(
                        premium: premium,
                        selected: selected,
                      ),
                      width: 0.55,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
