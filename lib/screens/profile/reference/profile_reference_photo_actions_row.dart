/// Photo action row — wraps; never a fixed height that clips CTAs.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../copy/profile_copy.dart';

class ProfileReferencePhotoActionsRow extends StatelessWidget {
  const ProfileReferencePhotoActionsRow({
    super.key,
    required this.hasPhoto,
    required this.onPhotoTap,
    this.onPhotoRemove,
  });

  final bool hasPhoto;
  final VoidCallback onPhotoTap;
  final VoidCallback? onPhotoRemove;

  @override
  Widget build(BuildContext context) {
    if (!hasPhoto) {
      return OraclyButton(
        text: ProfileCopy.photoAdd,
        onPressed: onPhotoTap,
        type: OraclyButtonType.secondary,
        size: OraclyButtonSize.small,
      );
    }
    return Row(
      children: [
        Expanded(
          child: OraclyButton(
            text: ProfileCopy.photoReplace,
            onPressed: onPhotoTap,
            type: OraclyButtonType.secondary,
            size: OraclyButtonSize.small,
          ),
        ),
        if (onPhotoRemove != null) ...[
          SizedBox(width: AppSpacing.s8),
          Expanded(
            child: OraclyButton(
              text: ProfileCopy.photoRemove,
              onPressed: onPhotoRemove,
              type: OraclyButtonType.danger,
              size: OraclyButtonSize.small,
            ),
          ),
        ],
      ],
    );
  }
}
