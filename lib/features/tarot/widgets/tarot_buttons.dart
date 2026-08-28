import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'tarot_typography.dart';

class TarotGoldButton extends StatelessWidget {
  const TarotGoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final btn = OraclyPressable(
      enabled: enabled,
      onTap: onPressed,
      label: label,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [AppColors.goldLight, AppColors.gold, const Color(0xFFB8862E)],
          ),
          boxShadow: enabled ? AppShadows.goldGlow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Icon(icon, size: 18, color: const Color(0xFF1A1020)),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                busy ? 'Karıştırılıyor...' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TarotTypography.body(size: 14).copyWith(
                  color: const Color(0xFF1A1020),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class TarotGlassButton extends StatelessWidget {
  const TarotGlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final btn = OraclyPressable(
      onTap: onPressed,
      label: label,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.card.withValues(alpha: 0.75),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(
                child: Icon(icon, size: 18, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TarotTypography.body(size: 13),
              ),
            ),
          ],
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
