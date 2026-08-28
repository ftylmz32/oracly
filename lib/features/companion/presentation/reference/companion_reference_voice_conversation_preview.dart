/// Calm Premium preview for voice conversation — explains, never fakes access.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../features/tarot/presentation/epic031/tarot_epic031_primary_button.dart';
import '../../../../shared/ui/oracly_bottom_sheet.dart';
import '../../copy/companion_copy.dart';

abstract final class CompanionReferenceVoiceConversationPreview {
  CompanionReferenceVoiceConversationPreview._();

  static Future<void> show(BuildContext context) {
    return OraclyBottomSheet.show<void>(
      context,
      title: CompanionCopy.voiceConversationPreviewTitle,
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final cream = OraclyChrome.cream;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            CompanionCopy.voiceConversationPreviewLead,
            textAlign: TextAlign.center,
            style: ReadingTypography.body(
              color: cream.withValues(alpha: 0.88),
            ),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CompanionCopy.voiceConversationPreviewBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.bodySmall(
              color: cream.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CompanionCopy.voiceConversationPreviewAside,
            textAlign: TextAlign.center,
            style: ReadingTypography.bodySmall(
              color: OraclyChrome.goldLight.withValues(alpha: 0.82),
            ),
          ),
          SizedBox(height: AppSpacing.s16),
          TarotEpic031PrimaryButton(
            label: PremiumCopy.ctaExplore,
            onPressed: () {
              Navigator.of(context).maybePop();
              OraclyNavigationService.openPremium(context);
            },
          ),
        ],
      ),
    );
  }
}
