/// One Profile utility row — brass well, label, quiet chevron.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'profile_reference_tokens.dart';

class ProfileQuickActionRow extends StatelessWidget {
  const ProfileQuickActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.40),
                      width: 0.85,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        OraclyChrome.gold.withValues(alpha: 0.14),
                        OraclyChrome.midnight.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: ProfileReferenceTokens.settingsIconWell,
                    height: ProfileReferenceTokens.settingsIconWell,
                    child: Icon(
                      icon,
                      size: 16,
                      color: OraclyChrome.goldLight.withValues(alpha: 0.90),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    label,
                    softWrap: true,
                    style: ReadingTypography.bodyCore(
                      color: OraclyChrome.cream.withValues(alpha: 0.90),
                    ).copyWith(letterSpacing: 0.2),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
