import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

class OraclyButton extends StatefulWidget {
  const OraclyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  State<OraclyButton> createState() => _OraclyButtonState();
}

class _OraclyButtonState extends State<OraclyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: AppDuration.fast,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.88 : 1,
        duration: AppDuration.fast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                AppColors.card.withValues(alpha: 0.9),
              ],
            ),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            boxShadow: AppShadows.goldGlow,
          ),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: AppColors.goldLight),
                const SizedBox(width: 10),
              ],
              Text(widget.label, style: AppTextStyles.button),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: widget.expanded ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}
