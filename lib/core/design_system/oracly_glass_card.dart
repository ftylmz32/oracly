/// Premium glass card surface — shared across every Oracly screen.
library;

import 'package:flutter/material.dart';

import '../../shared/widgets/oracly_pressable.dart';
import 'oracly_chrome.dart';
import 'oracly_glass_card_sheen.dart';
import 'oracly_surface_depth.dart';
import 'oracly_surface_style.dart';

/// Dark celestial glass with antique gold edge — never Material Card.
///
/// [premium] → hero · [elevated] → mid · [selected] → active gold rim.
class OraclyGlassCard extends StatelessWidget {
  const OraclyGlassCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.padding,
    this.borderRadius = OraclyChrome.cardRadius,
    this.onTap,
    this.premium = false,
    this.elevated = false,
    this.selected = false,
    this.glowStrength = 1.0,
  });

  final Widget child;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool premium;
  final bool elevated;
  final bool selected;
  final double glowStrength;

  LinearGradient _fill(Brightness brightness) {
    if (selected) return OraclySurfaceStyle.glassSelectedOf(brightness);
    if (premium) return OraclySurfaceStyle.glassPremiumOf(brightness);
    if (elevated) return OraclySurfaceStyle.glassElevatedOf(brightness);
    return OraclySurfaceStyle.glassFillOf(brightness);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;

    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: _fill(brightness),
        border: Border.all(
          color: OraclySurfaceDepth.goldEdge(
            selected: selected,
            premium: premium,
            elevated: elevated,
            glowStrength: glowStrength,
          ),
          width: OraclySurfaceDepth.goldEdgeWidth(
            selected: selected,
            premium: premium,
            elevated: elevated,
          ),
        ),
        boxShadow: OraclySurfaceDepth.cardShadows(
          premium: premium,
          selected: selected,
          elevated: elevated,
          isLight: isLight,
          glowStrength: glowStrength,
        ),
      ),
      child: OraclyGlassCardSheen(
        padding: padding ?? EdgeInsets.zero,
        borderRadius: borderRadius,
        premium: premium,
        selected: selected,
        child: child,
      ),
    );

    final sized = SizedBox(width: width, height: height, child: body);
    if (onTap == null) return sized;
    return OraclyPressable(
      onTap: onTap,
      borderRadius: borderRadius,
      glowShift: true,
      child: sized,
    );
  }
}
