/// Tiny last-OR actions — only when useful. Never a constant toolbar.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/insight_copy/insight_copy_action.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../../favorite_moments/models/favorite_moment.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../copy/companion_copy.dart';

class CompanionOrMessageActions extends StatelessWidget {
  const CompanionOrMessageActions({
    super.key,
    required this.message,
    required this.onSpeak,
    required this.onRegenerate,
    this.showSpeak = false,
    this.showRetry = true,
    this.saveDraft,
  });

  final AIMessage message;
  final ValueChanged<String> onSpeak;
  final VoidCallback onRegenerate;
  final bool showSpeak;
  final bool showRetry;
  final FavoriteMoment? saveDraft;

  @override
  Widget build(BuildContext context) {
    if (message.content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 2),
      child: Wrap(
        spacing: 2,
        runSpacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _TinyAction(
            label: CompanionCopy.copyAction,
            onTap: () => InsightCopyAction.copy(context, message.content),
          ),
          if (showSpeak)
            _TinyAction(
              label: CompanionCopy.speakAction,
              onTap: () => onSpeak(message.content),
            ),
          if (saveDraft != null)
            SaveFavoriteMomentLink(
              draft: saveDraft!,
              align: Alignment.centerLeft,
            ),
          if (showRetry)
            _TinyAction(
              label: CompanionCopy.regenerateAction,
              onTap: onRegenerate,
            ),
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({required this.label, required this.onTap});

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
          constraints: const BoxConstraints(
            minHeight: OraclyA11y.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: OraclyChrome.goldLight.withValues(
                  alpha: OraclyA11y.quietGoldMuted,
                ),
                fontSize: 11,
                letterSpacing: 0.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
