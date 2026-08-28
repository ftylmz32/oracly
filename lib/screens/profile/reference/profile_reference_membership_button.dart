/// Gold membership CTA for the Profile card.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'profile_reference_tokens.dart';

class ProfileReferenceMembershipButton extends StatefulWidget {
  const ProfileReferenceMembershipButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<ProfileReferenceMembershipButton> createState() =>
      _ProfileReferenceMembershipButtonState();
}

class _ProfileReferenceMembershipButtonState
    extends State<ProfileReferenceMembershipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      borderRadius: ProfileReferenceTokens.statRadius,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: ProfileReferenceTokens.statRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.goldLight.withValues(alpha: _pressed ? 0.86 : 0.98),
                AppColors.gold.withValues(alpha: _pressed ? 0.82 : 0.94),
                AppColors.goldDeep.withValues(alpha: _pressed ? 0.78 : 0.88),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldGlow.withValues(alpha: 0.24),
                blurRadius: 16,
                offset: Offset(0, _pressed ? 2 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.purpleDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
