import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';

/// Thin gold icon with soft glow — ORACLY icon language.
class OraclyIcon extends StatelessWidget {
  const OraclyIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
  });

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: AppShadows.iconGlow),
      child: Icon(
        icon,
        size: size,
        color: color ?? AppColors.goldLight,
      ),
    );
  }
}
