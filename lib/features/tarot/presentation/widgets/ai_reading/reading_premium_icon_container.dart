/// OR-301+ — Glass circular icon container for reading sections.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'reading_section_theme.dart';

class ReadingPremiumIconContainer extends StatelessWidget {
  const ReadingPremiumIconContainer({
    super.key,
    required this.theme,
    this.size = 38,
  });

  final ReadingSectionTheme theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.iconGlow.withValues(alpha: 0.22),
              blurRadius: 10,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.surfaceElevated.withValues(alpha: 0.85),
                    AppColors.purpleDark.withValues(alpha: 0.55),
                  ],
                ),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.75),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(
                  theme.icon,
                  size: size * 0.42,
                  color: theme.iconGlow,
                  shadows: [
                    Shadow(
                      color: theme.iconGlow.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
