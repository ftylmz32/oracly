/// Localized membership chip — never a mixed-language STANDART leftover.
library;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsMembershipBadge extends StatelessWidget {
  const SettingsMembershipBadge({
    super.key,
    required this.isPremium,
    required this.languageCode,
  });

  final bool isPremium;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFFF0D77A), Color(0xFFD4AF37)],
              )
            : LinearGradient(
                colors: [
                  p.surface.withValues(alpha: 0.65),
                  p.purple.withValues(alpha: 0.55),
                ],
              ),
        border: Border.all(
          color: p.gold.withValues(alpha: isPremium ? 0.45 : 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          isPremium
              ? OraclyL10n.t(
                  L10nKeys.membershipPremium,
                  languageCode: languageCode,
                )
              : OraclyL10n.t(
                  L10nKeys.membershipStandard,
                  languageCode: languageCode,
                ),
          style: AppTextStyles.caption.copyWith(
            color: isPremium ? AppColors.purpleDark : p.goldLight,
            fontWeight: FontWeight.w800,
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
