/// Discovery tile press — doorway into a chamber, never a bounce.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_art_direction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../../core/theme/oracly_reduced_motion.dart';
import '../../../shared/widgets/oracly_pressable.dart';

/// Image drifts inward, shadow deepens, gold edge catches light.
class HomeDiscoveryPortal extends StatefulWidget {
  const HomeDiscoveryPortal({
    super.key,
    required this.child,
    required this.art,
    required this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final Widget art;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  @override
  State<HomeDiscoveryPortal> createState() => _HomeDiscoveryPortalState();
}

class _HomeDiscoveryPortalState extends State<HomeDiscoveryPortal> {
  bool _pressed = false;

  Duration _motionDuration(BuildContext context) {
    final base = _pressed
        ? OraclySignatureMotion.press
        : OraclySignatureMotion.pressRelease;
    return OraclyReducedMotion.duration(context, base);
  }

  Curve get _curve =>
      _pressed ? OraclySignatureMotion.curve : OraclySignatureMotion.releaseCurve;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    final reduced = OraclyReducedMotion.of(context);
    final goldA = OraclyArtDirection.clampGoldGlow(_pressed ? 0.24 : 0.14);
    final edge = _pressed
        ? AppColors.goldLight.withValues(alpha: 0.72)
        : AppColors.gold.withValues(alpha: 0.52);
    final duration = _motionDuration(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          OraclyTouchFeedback.selection();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: duration,
          curve: _curve,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: edge,
              width: _pressed ? 1.4 : 1.05,
            ),
              boxShadow: [
              BoxShadow(
                color: AppColors.nearBlack.withValues(
                  alpha: _pressed ? 0.40 : 0.28,
                ),
                blurRadius: _pressed ? 10 : 14,
                offset: Offset(0, _pressed ? 2 : 5),
                spreadRadius: -3,
              ),
              BoxShadow(
                color: AppColors.glowPurple.withValues(
                  alpha: _pressed ? 0.10 : 0.07,
                ),
                blurRadius: 12,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColors.glowGold.withValues(alpha: goldA),
                blurRadius: _pressed ? 14 : 9,
                spreadRadius: _pressed ? 0.5 : -1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: reduced ? 1.0 : (_pressed ? 1.018 : 1.0),
                  duration: duration,
                  curve: _curve,
                  alignment: Alignment.center,
                  child: AnimatedSlide(
                    offset: reduced
                        ? Offset.zero
                        : (_pressed
                            ? const Offset(0, 0.008)
                            : Offset.zero),
                    duration: duration,
                    curve: _curve,
                    child: widget.art,
                  ),
                ),
                widget.child,
                // Inner velvet gold lip.
                IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: AppColors.ivory.withValues(
                            alpha: _pressed ? 0.14 : 0.08,
                          ),
                          width: 0.55,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
