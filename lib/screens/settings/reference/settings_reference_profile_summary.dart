/// Reference profile summary card at top of Settings.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/reference/profile_avatar_letter.dart';
import '../../profile/reference/profile_reference_avatar.dart';
import 'settings_membership_badge.dart';
import 'settings_reference_card_shell.dart';
import 'settings_reference_tokens.dart';

class SettingsReferenceProfileSummary extends StatelessWidget {
  const SettingsReferenceProfileSummary({
    super.key,
    required this.name,
    required this.isPremium,
    required this.subtitle,
    required this.emptyName,
    this.languageCode = 'tr',
    this.photo,
    this.onTap,
  });

  final String name;
  final bool isPremium;
  final String subtitle;
  final String emptyName;
  final String languageCode;
  final ImageProvider? photo;
  final VoidCallback? onTap;

  String get _displayName => name.trim().isEmpty ? emptyName : name.trim();

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return SettingsReferenceCardShell(
      borderRadius: SettingsReferenceTokens.profileRadius,
      padding: SettingsReferenceTokens.profilePadding,
      onTap: onTap,
      glowStrength: 1.08,
      child: Row(
        children: [
          ProfileReferenceAvatar(
            initials: ProfileAvatarLetter.of(_displayName),
            identity: _displayName,
            photo: photo,
            size: SettingsReferenceTokens.profileAvatarSize,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _displayName,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary.withValues(alpha: 0.94),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: SettingsMembershipBadge(
                        isPremium: isPremium,
                        languageCode: languageCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: p.textSecondary.withValues(alpha: 0.72),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: p.goldLight.withValues(alpha: 0.72),
          ),
        ],
      ),
    );
  }
}
