/// OR-004.3 / OR-026 — Daily energy card action button.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_radius.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../theme/home_focus.dart';
import '../../theme/home_reward.dart';



/// "Detayını Gör" — premium outlined action with soft press feedback.

class EnergyAction extends StatefulWidget {

  const EnergyAction({

    super.key,

    this.onPressed,

  });



  final VoidCallback? onPressed;



  static const String _label = 'Detayını Gör';



  @override

  State<EnergyAction> createState() => _EnergyActionState();

}



class _EnergyActionState extends State<EnergyAction> {

  bool _pressed = false;



  bool get _isInteractive => widget.onPressed != null;



  @override

  Widget build(BuildContext context) {

    final borderColor = _isInteractive

        ? AppColors.gold.withValues(alpha: _pressed ? 0.38 : 0.24)

        : AppColors.divider;

    final background = _isInteractive

        ? (_pressed

            ? AppColors.surfaceElevated.withValues(alpha: 0.92)

            : AppColors.surface.withValues(alpha: 0.55))

        : AppColors.surface.withValues(alpha: 0.35);

    final foreground = _isInteractive

        ? AppColors.goldLight

        : AppColors.textHint;



    return OraclyPressable(
      onTap: _isInteractive ? widget.onPressed : null,
      enabled: _isInteractive,
      onTapDown: _isInteractive ? (_) => _setPressed(true) : null,
      onTapUp: _isInteractive ? (_) => _setPressed(false) : null,
      onTapCancel: _isInteractive ? () => _setPressed(false) : null,
      scale: false,
      depth: false,
      opacity: false,
      child: Transform.translate(
        offset: Offset(0, HomeReward.depthCompress(_pressed && _isInteractive)),
        child: AnimatedScale(
          scale: HomeReward.pressScale(_pressed && _isInteractive),
          duration: _pressed ? HomeReward.press : HomeReward.release,
          curve: _pressed ? HomeReward.curve : HomeReward.releaseCurve,
          child: AnimatedContainer(
            duration: _pressed ? HomeReward.press : HomeReward.release,
            curve: _pressed ? HomeReward.curve : HomeReward.releaseCurve,
            decoration: BoxDecoration(
              borderRadius: AppRadius.sm,
              color: background,
              border: Border.all(
                color: borderColor,
                width: AppBorderWidth.hairline,
              ),
              boxShadow: _isInteractive
                  ? [
                      BoxShadow(
                        color: AppColors.goldGlow.withValues(
                          alpha: _pressed ? 0.10 : 0.16,
                        ),
                        blurRadius: AppSpacing.sm,
                        offset: Offset(0, _pressed ? 1 : 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: HomeLuxuryReflection(
                    pressed: _pressed && _isInteractive,
                    borderRadius: AppRadius.sm,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + AppSpacing.xs,
                    vertical: AppSpacing.sm + 1,
                  ),
                  child: Text(
                    EnergyAction._label,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.45,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    setState(() => _pressed = value);
    final scope = HomeFocusScope.maybeOf(context);
    if (scope == null) return;
    if (value) {
      scope.onActivate(HomeFocusZone.daily);
    } else {
      scope.onRelease();
    }
  }
}

