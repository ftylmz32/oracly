import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../widgets/luxury_glass_surface.dart';

class QuickActionTile extends StatefulWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.phase = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final double phase;

  @override
  State<QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<QuickActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5200 + (widget.phase * 400).round()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idle,
      builder: (_, child) {
        final drift = (_idle.value - 0.5) * 1.5;
        return Transform.translate(
          offset: Offset(0, drift),
          child: child,
        );
      },
      child: OraclyPressable(
        onTap: widget.onTap,
        child: LuxuryGlassSurface(
          height: 132,
          elevated: true,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconWell(icon: widget.icon),
              const Spacer(),
              Text(
                widget.title,
                style: AppTextStyles.title.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.16),
            AppColors.textPrimary.withValues(alpha: 0.04),
            AppColors.surface.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.09),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 7,
            left: 10,
            right: 10,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.textPrimary.withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: 23,
              color: AppColors.textPrimary.withValues(alpha: 0.93),
            ),
          ),
        ],
      ),
    );
  }
}
