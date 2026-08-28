/// Reference dream screen — dual action buttons below hero.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

/// Equal-width rounded action buttons — write and voice.
class DreamActionButtons extends StatelessWidget {
  const DreamActionButtons({
    super.key,
    required this.onWriteTap,
    required this.onVoiceTap,
  });

  final VoidCallback onWriteTap;
  final VoidCallback onVoiceTap;

  static const double buttonHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DreamActionButton(
            label: 'Rüyanı Yaz',
            icon: Icons.edit_outlined,
            onTap: onWriteTap,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _DreamActionButton(
            label: 'Sesli Anlat',
            icon: Icons.mic_none_rounded,
            onTap: onVoiceTap,
          ),
        ),
      ],
    );
  }
}

class _DreamActionButton extends StatefulWidget {
  const _DreamActionButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  State<_DreamActionButton> createState() => _DreamActionButtonState();
}

class _DreamActionButtonState extends State<_DreamActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      borderRadius: AppRadius.round,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: DreamActionButtons.buttonHeight,
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceElevated.withValues(alpha: _pressed ? 0.78 : 0.88),
              AppColors.surface.withValues(alpha: _pressed ? 0.62 : 0.72),
            ],
          ),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: _pressed ? 0.38 : 0.28),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: _pressed ? 0.10 : 0.16),
              blurRadius: 14,
              offset: Offset(0, _pressed ? 1 : 3),
            ),
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.08),
              blurRadius: 18,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 18,
              color: AppColors.goldLight.withValues(alpha: 0.88),
            ),
            SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.goldLight.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
