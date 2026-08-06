/// OR-301+ — Primary button with unified Oracly touch language.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';

class ReadingPremiumTapButton extends StatelessWidget {
  const ReadingPremiumTapButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.glowColor,
    this.borderRadius,
    this.height,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final glow = glowColor ?? AppColors.gold;
    final radius = borderRadius ?? AppRadius.lg;

    return OraclyPressable(
      enabled: enabled,
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            width: double.infinity,
            height: height ?? AppSpacing.xxl + AppSpacing.xs,
            child: child,
          ),
        ),
      ),
    );
  }
}
