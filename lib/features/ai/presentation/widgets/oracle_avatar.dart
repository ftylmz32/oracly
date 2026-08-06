/// OR-1110 — OR Oracle avatar for AI surfaces.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OracleAvatar extends StatefulWidget {
  const OracleAvatar({
    super.key,
    this.size = 36,
    this.showGlow = true,
  });

  final double size;
  final bool showGlow;

  @override
  State<OracleAvatar> createState() => _OracleAvatarState();
}

class _OracleAvatarState extends State<OracleAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final glow = 0.5 + sin(_breath.value * pi) * 0.5;
        return Container(
          width: widget.size + (widget.showGlow ? 10 : 0),
          height: widget.size + (widget.showGlow ? 10 : 0),
          decoration: widget.showGlow
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleGlow
                          .withValues(alpha: 0.3 + glow * 0.2),
                      blurRadius: 12 + glow * 6,
                    ),
                  ],
                )
              : null,
          child: Center(
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldLight.withValues(alpha: 0.85),
                    AppColors.purple.withValues(alpha: 0.75),
                    AppColors.purpleDark,
                  ],
                ),
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.45),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: widget.size * 0.32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
