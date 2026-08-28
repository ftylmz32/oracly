/// OR-002.1 — Premium reusable CTA button for Oracly.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/premium_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'chamber_waiting_orb.dart';
import 'oracly_pressable.dart';

/// Visual emphasis level for [OraclyButton].
enum OraclyButtonType {
  primary,
  secondary,
  ghost,
  danger,
}

/// Layout density for [OraclyButton].
enum OraclyButtonSize {
  small,
  medium,
  large,
}

/// Material 3–aligned premium call-to-action button.
///
/// Delegates standard variants to [PremiumButton]; keeps [danger] locally.
class OraclyButton extends StatelessWidget {
  const OraclyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.enabled = true,
    this.type = OraclyButtonType.primary,
    this.size = OraclyButtonSize.medium,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final bool enabled;
  final OraclyButtonType type;
  final OraclyButtonSize size;

  PremiumButtonVariant? get _premiumVariant => switch (type) {
        OraclyButtonType.primary => PremiumButtonVariant.primary,
        OraclyButtonType.secondary => PremiumButtonVariant.secondary,
        OraclyButtonType.ghost => PremiumButtonVariant.ghost,
        OraclyButtonType.danger => null,
      };

  PremiumButtonSize get _premiumSize => switch (size) {
        OraclyButtonSize.small => PremiumButtonSize.small,
        OraclyButtonSize.medium => PremiumButtonSize.medium,
        OraclyButtonSize.large => PremiumButtonSize.large,
      };

  @override
  Widget build(BuildContext context) {
    final variant = _premiumVariant;
    if (variant != null) {
      return PremiumButton(
        label: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        isExpanded: isExpanded,
        enabled: enabled,
        variant: variant,
        size: _premiumSize,
      );
    }

    return _DangerButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      isExpanded: isExpanded,
      enabled: enabled,
      size: size,
    );
  }
}

class _DangerButton extends StatefulWidget {
  const _DangerButton({
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.isLoading,
    required this.isExpanded,
    required this.enabled,
    required this.size,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final bool enabled;
  final OraclyButtonSize size;

  @override
  State<_DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<_DangerButton> {
  bool get _isInteractive =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsFor(widget.size);

    final button = OraclyPressable(
      enabled: _isInteractive,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      borderRadius: AppRadius.lg,
      child: Container(
        width: widget.isExpanded ? double.infinity : null,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.lg,
          boxShadow: _isInteractive ? AppShadows.soft : null,
        ),
        child: Padding(
          padding: metrics.padding,
          child: Center(
            child: widget.isLoading
                ? ChamberWaitingOrb(
                    size: metrics.indicatorSize,
                    seed: widget.text.hashCode,
                  )
                : _ButtonContent(
                    text: widget.text,
                    icon: widget.icon,
                    foreground: _isInteractive
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    iconSize: metrics.iconSize,
                  ),
          ),
        ),
      ),
    );

    if (_isInteractive) return button;
    return Opacity(opacity: 0.55, child: button);
  }

  static _OraclyButtonMetrics _metricsFor(OraclyButtonSize size) {
    return switch (size) {
      OraclyButtonSize.small => _OraclyButtonMetrics(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          iconSize: AppSpacing.md,
          indicatorSize: AppSpacing.md,
        ),
      OraclyButtonSize.medium => _OraclyButtonMetrics(
          padding: AppDecorations.contentPadding(),
          iconSize: AppSpacing.md + AppSpacing.xs,
          indicatorSize: AppSpacing.md + AppSpacing.xs,
        ),
      OraclyButtonSize.large => _OraclyButtonMetrics(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          iconSize: AppSpacing.lg,
          indicatorSize: AppSpacing.lg,
        ),
    };
  }
}

@immutable
class _OraclyButtonMetrics {
  const _OraclyButtonMetrics({
    required this.padding,
    required this.iconSize,
    required this.indicatorSize,
  });

  final EdgeInsets padding;
  final double iconSize;
  final double indicatorSize;
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.icon,
    required this.foreground,
    required this.iconSize,
  });

  final String text;
  final IconData? icon;
  final Color foreground;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(color: foreground),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (icon == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: foreground),
        SizedBox(width: AppSpacing.sm),
        Flexible(child: label),
      ],
    );
  }
}
