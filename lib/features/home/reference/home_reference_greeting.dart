/// Reference home greeting — compact warm hierarchy from 01_home.png.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/first_session_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'home_reference_scope.dart';

class HomeReferenceGreeting extends StatelessWidget {
  const HomeReferenceGreeting({
    super.key,
    this.userName = '',
  });

  final String userName;

  static String get referenceSubtitle => OraclyL10n.t('home.reference_subtitle');

  @override
  Widget build(BuildContext context) {
    final layout = HomeReferenceScope.maybeOf(context);
    final titleSize = layout?.greetingTitleSize ?? 22;
    final subtitleSize = layout?.greetingSubtitleSize ?? 13;
    final name = userName.trim().isEmpty
        ? FirstSessionCopy.homeGuestName
        : userName.trim();

    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              OraclyL10n.t('home.hello_named').replaceAll('{name}', name),
              style: AppTypography.headingXl.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.96),
                fontWeight: FontWeight.w600,
                height: 1.08,
                letterSpacing: -0.15,
                fontSize: titleSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              referenceSubtitle,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.78),
                height: 1.2,
                letterSpacing: 0.08,
                fontWeight: FontWeight.w400,
                fontSize: subtitleSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
