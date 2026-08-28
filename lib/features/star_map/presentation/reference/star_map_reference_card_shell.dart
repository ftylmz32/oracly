/// Archive plate shell — warm parchment / brass edge. Not instrument glass.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_radius.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'star_map_reference_tokens.dart';

class StarMapReferenceCardShell extends StatelessWidget {
  const StarMapReferenceCardShell({
    super.key,
    required this.child,
    this.height,
    this.padding,
    this.borderRadius = AppRadius.s20,
    this.onTap,
    this.premium = false,
    this.elevated = false,
    this.glowStrength = 1.0,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool premium;
  final bool elevated;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    final brass = StarMapReferenceTokens.brassGlow;
    final candle = StarMapReferenceTokens.candleAmber;
    final body = Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1510).withValues(alpha: elevated ? 0.94 : 0.88),
            const Color(0xFF0E0908).withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: brass.withValues(
            alpha: premium ? 0.44 : 0.30 * glowStrength.clamp(0.4, 1.2),
          ),
          width: premium ? 1.15 : 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: elevated ? 14 : 8,
            offset: Offset(0, elevated ? 5 : 3),
          ),
          if (premium)
            BoxShadow(
              color: candle.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return body;
    return OraclyPressable(onTap: onTap, child: body);
  }
}
