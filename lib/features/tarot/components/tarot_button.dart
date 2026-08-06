/// OR-1000 — Tarot button primitives.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../theme/tarot_theme.dart';

/// Base tarot button with press feedback — extend for variants.
abstract class TarotButton extends StatefulWidget {
  const TarotButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool busy;

  bool get enabled => onPressed != null && !busy;

  BoxDecoration decoration(bool enabled, bool pressed);
  Color get foregroundColor;

  @override
  State<TarotButton> createState() => _TarotButtonState();
}

class _TarotButtonState extends State<TarotButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.enabled ? widget.onPressed : null,
      enabled: widget.enabled,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: _pressed
            ? OraclySignatureMotion.press
            : OraclySignatureMotion.pressRelease,
        curve: _pressed
            ? OraclySignatureMotion.curve
            : OraclySignatureMotion.releaseCurve,
        height: AppSpacing.xxl + AppSpacing.sm,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: widget.decoration(widget.enabled, _pressed),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.busy)
              ChamberWaitingOrb(
                size: AppSpacing.md,
                seed: widget.label.hashCode,
              )
            else if (widget.icon != null) ...[
              Icon(widget.icon, size: AppSpacing.md, color: widget.foregroundColor),
              SizedBox(width: AppSpacing.sm),
            ],
            Text(
              widget.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: widget.foregroundColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold gradient call-to-action.
class TarotPrimaryButton extends TarotButton {
  const TarotPrimaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.expanded,
    super.busy,
  });

  @override
  BoxDecoration decoration(bool enabled, bool pressed) {
    return TarotTheme.primaryButtonDecoration(enabled: enabled);
  }

  @override
  Color get foregroundColor => AppColors.primary;
}

/// Outlined glass secondary action.
class TarotSecondaryButton extends TarotButton {
  const TarotSecondaryButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.expanded,
    super.busy,
  });

  @override
  BoxDecoration decoration(bool enabled, bool pressed) {
    return TarotTheme.secondaryButtonDecoration(enabled: enabled);
  }

  @override
  Color get foregroundColor =>
      enabled ? AppColors.goldLight : AppColors.textHint;
}
