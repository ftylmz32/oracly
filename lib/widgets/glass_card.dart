import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/oracly_brand_signature.dart';
import '../core/widgets/oracly_signature_motifs.dart';
import '../shared/widgets/oracly_pressable.dart';

/// Canonical ORACLY glass card — gold outline, purple glow, soft blur.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.radius = AppRadius.glassValue,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: OraclySignatureMicroFrame(
          borderRadius: BorderRadius.circular(widget.radius),
          cornerInset: 14,
          cornerSize: 13,
          opacity: 0.82,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: OraclySignatureMaterials.blurChamber,
              sigmaY: OraclySignatureMaterials.blurChamber,
            ),
            child: Container(
              width: double.infinity,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: OraclySignatureChamber.crystalBody(),
                border: Border.all(
                  color: OraclySignaturePalette.goldEngrave(
                    OraclySignatureMaterials.goldBorder,
                  ),
                  width: AppBorderWidth.hairline + 0.35,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return OraclyPressable(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
