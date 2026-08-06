/// OR-002.1 — Premium reusable CTA button for Oracly.
library;

import 'package:flutter/material.dart';

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
/// Built with [Container] + [InkWell]; no Material button widgets.
class OraclyButton extends StatefulWidget {
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

  @override
  State<OraclyButton> createState() => _OraclyButtonState();
}

class _OraclyButtonState extends State<OraclyButton> {
  bool get _isInteractive =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final metrics = _OraclyButtonState.forSize(widget.size);
    final decoration = _OraclyButtonState._decorationFor(widget.type, _isInteractive);
    final foreground = _OraclyButtonState._foregroundFor(widget.type, _isInteractive);

    final button = OraclyPressable(
      enabled: _isInteractive,
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: widget.isExpanded ? double.infinity : null,
        decoration: decoration,
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
                    foreground: foreground,
                    iconSize: metrics.iconSize,
                  ),
          ),
        ),
      ),
    );

    if (_isInteractive) return button;

    return Opacity(opacity: _DisabledOpacity.surface, child: button);
  }

  static BoxDecoration _decorationFor(
    OraclyButtonType type,
    bool isInteractive,
  ) {
    return switch (type) {
      OraclyButtonType.primary => BoxDecoration(
          gradient: AppGradients.goldBorder,
          borderRadius: AppRadius.lg,
          boxShadow: isInteractive ? AppShadows.goldGlow : null,
        ),
      OraclyButtonType.secondary => AppDecorations.mattePanel(
          borderRadius: AppRadius.lg,
        ),
      OraclyButtonType.ghost => BoxDecoration(
          color: AppColors.transparent,
          borderRadius: AppRadius.lg,
          border: Border.all(
            color: AppColors.border,
            width: AppBorderWidth.thin,
          ),
        ),
      OraclyButtonType.danger => BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.lg,
          boxShadow: isInteractive ? AppShadows.soft : null,
        ),
    };
  }

  static Color _foregroundFor(OraclyButtonType type, bool isInteractive) {
    final color = switch (type) {
      OraclyButtonType.primary => AppColors.background,
      OraclyButtonType.secondary => AppColors.goldLight,
      OraclyButtonType.ghost => AppColors.goldLight,
      OraclyButtonType.danger => AppColors.textPrimary,
    };

    if (isInteractive) return color;
    return AppColors.textHint;
  }

  static _OraclyButtonMetrics forSize(OraclyButtonSize size) {
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

abstract final class _DisabledOpacity {
  _DisabledOpacity._();

  static const double surface = 0.55;
}
