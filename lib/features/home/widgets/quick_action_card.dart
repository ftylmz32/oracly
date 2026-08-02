import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';

class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _pressed = false;

  Color _accentColor() {
    switch (widget.title) {
      case 'AI Sohbet':
        return AppColors.accent;
      case 'Tarot':
        return AppColors.primary;
      case 'Astroloji':
        return AppColors.cyan;
      case 'Hafıza':
        return AppColors.success;
      case 'Profil':
        return AppColors.info;
      case 'Ayarlar':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .1),
                  border: Border.all(
                    color: color.withValues(alpha: .18),
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: Icon(
                  widget.icon,
                  size: 34,
                  color: color.withValues(alpha: .92),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
