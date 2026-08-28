/// Compact premium glass action rows.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_card_shell.dart';
import 'profile_reference_tokens.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceSettingsItem {
  const ProfileReferenceSettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;
}

class ProfileReferenceSettingsSection extends StatelessWidget {
  const ProfileReferenceSettingsSection({super.key, required this.items});

  final List<ProfileReferenceSettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: ProfileReferenceTokens.settingsItemGap),
          _SettingsRow(item: items[i]),
        ],
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final ProfileReferenceSettingsItem item;

  @override
  Widget build(BuildContext context) {
    final active = item.subtitle == ProfileCopy.premiumActive;
    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      borderRadius: ProfileReferenceTokens.settingsRadius,
      padding: ProfileReferenceTokens.settingsPadding,
      glowStrength: 0.55,
      onTap: item.onTap,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OraclyChrome.gold.withValues(alpha: 0.14),
                  OraclyChrome.midnight.withValues(alpha: 0.55),
                ],
              ),
              border: Border.all(
                color: OraclyChrome.goldLight.withValues(alpha: 0.40),
                width: 0.85,
              ),
            ),
            child: SizedBox(
              width: ProfileReferenceTokens.settingsIconWell,
              height: ProfileReferenceTokens.settingsIconWell,
              child: Icon(
                item.icon,
                size: 16,
                color: OraclyChrome.goldLight.withValues(alpha: 0.90),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: ReadingTypography.bodyCore(
                    color: OraclyChrome.cream.withValues(alpha: 0.92),
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      height: 1.2,
                      color: active
                          ? const Color(0xFF6FCF97)
                          : OraclyChrome.cream.withValues(alpha: 0.68),
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (item.trailing != null) ...[
            Text(
              item.trailing!,
              style: AppTextStyles.caption.copyWith(
                color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: OraclyChrome.goldLight.withValues(alpha: 0.55),
          ),
        ],
      ),
    );
  }
}
