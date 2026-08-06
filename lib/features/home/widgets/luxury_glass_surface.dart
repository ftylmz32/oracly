import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../../shared/widgets/oracly_pressable.dart';

/// Premium glass surface — ORACLY Design System V1.
class LuxuryGlassSurface extends StatefulWidget {
  const LuxuryGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 32,
    this.height,
    this.elevated = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? height;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  State<LuxuryGlassSurface> createState() => _LuxuryGlassSurfaceState();
}

class _LuxuryGlassSurfaceState extends State<LuxuryGlassSurface> {
  @override
  Widget build(BuildContext context) {
    final surface = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: widget.elevated ? AppShadows.card : AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: AppGradients.glass,
              border: Border.all(color: AppColors.glassBorder, width: 0.8),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) return surface;

    return OraclyPressable(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: surface,
    );
  }
}
