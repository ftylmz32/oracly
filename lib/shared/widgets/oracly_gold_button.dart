/// Premium gold CTA — stadium pill, restrained antique glow.
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/app_layout.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/theme/app_colors.dart';
import 'oracly_pressable.dart';

class OraclyGoldButton extends StatefulWidget {
  const OraclyGoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.borderRadius = OraclyChrome.pillRadius,
    this.minWidth,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final BorderRadius borderRadius;
  final double? minWidth;

  @override
  State<OraclyGoldButton> createState() => _OraclyGoldButtonState();
}

class _OraclyGoldButtonState extends State<OraclyGoldButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final button = OraclyPressable(
      onTap: widget.onPressed,
      enabled: enabled,
      label: widget.label,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      borderRadius: widget.borderRadius,
      glowShift: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minWidth: widget.minWidth ?? OraclyA11y.minTouchTarget,
          minHeight: OraclyA11y.minTouchTarget,
        ),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? [
                    AppColors.goldLight.withValues(
                      alpha: _pressed ? 0.88 : 0.98,
                    ),
                    AppColors.gold.withValues(alpha: _pressed ? 0.84 : 0.96),
                    AppColors.goldDeep.withValues(
                      alpha: _pressed ? 0.80 : 0.92,
                    ),
                  ]
                : [
                    AppColors.gold.withValues(alpha: 0.42),
                    AppColors.gold.withValues(alpha: 0.34),
                  ],
          ),
          border: Border.all(
            color: AppColors.goldLight.withValues(
              alpha: enabled ? (_pressed ? 0.34 : 0.26) : 0.22,
            ),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(
                      alpha: _pressed
                          ? OraclyChrome.glowSoft
                          : OraclyChrome.glowMedium,
                    ),
                    blurRadius: _pressed ? 10 : 16,
                    offset: Offset(0, _pressed ? 2 : 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: Offset(0, _pressed ? 1 : 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: AppLayout.referencePrimaryButtonPadding,
          child: Row(
            mainAxisSize:
                widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                ExcludeSemantics(
                  child: Icon(
                    widget.icon,
                    size: AppLayout.referenceIconSize,
                    color: OraclyChrome.midnight.withValues(alpha: 0.86),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OraclyChrome.ctaLabel(size: 15).copyWith(
                    color: OraclyChrome.midnight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
