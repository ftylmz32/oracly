/// Personal hero — atmospheric plate, real photo or ORACLY emblem, calm edit.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../copy/profile_copy.dart';
import 'profile_avatar_letter.dart';
import 'profile_reference_avatar.dart';
import 'profile_reference_card_shell.dart';
import 'profile_reference_hero_plate.dart';
import 'profile_reference_photo_actions_row.dart';
import 'profile_reference_tokens.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceHeader extends StatelessWidget {
  const ProfileReferenceHeader({
    super.key,
    required this.name,
    this.photo,
    this.onAvatarTap,
    this.onPhotoTap,
    this.onPhotoRemove,
  });

  final String name;
  final ImageProvider? photo;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onPhotoRemove;

  String get _displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? ProfileCopy.guestName : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.hero,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileReferenceHeroPlate(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  button: true,
                  label: ProfileCopy.photoTitle,
                  child: OraclyPressable(
                    onTap: onPhotoTap ?? onAvatarTap,
                    borderRadius: BorderRadius.circular(999),
                    child: ProfileReferenceAvatar(
                      initials: ProfileAvatarLetter.of(_displayName),
                      identity: _displayName,
                      photo: photo,
                      size: ProfileReferenceTokens.avatarSize,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.s12),
                OraclyPressable(
                  onTap: onAvatarTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _displayName,
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          style: AppTextStyles.title.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: OraclyChrome.goldLight.withValues(
                              alpha: 0.96,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: OraclyChrome.goldLight.withValues(alpha: 0.42),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.s4),
                Text(
                  ProfileCopy.spaceWhisper,
                  softWrap: true,
                  style: ReadingTypography.bodyCore(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                  ),
                ),
                if (onPhotoTap != null) ...[
                  SizedBox(height: AppSpacing.s12),
                  ProfileReferencePhotoActionsRow(
                    hasPhoto: hasPhoto,
                    onPhotoTap: onPhotoTap!,
                    onPhotoRemove: onPhotoRemove,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
