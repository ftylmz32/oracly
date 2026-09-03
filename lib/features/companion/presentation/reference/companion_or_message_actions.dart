/// Tiny last-Luna actions — copy · favorite · regenerate. Real only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/insight_copy/insight_copy_action.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../../favorite_moments/copy/favorite_moments_copy.dart';
import '../../../favorite_moments/models/favorite_moment.dart';
import '../../../favorite_moments/providers/favorite_moments_providers.dart';
import '../../copy/companion_copy.dart';
import 'companion_gold_line_icon.dart';
import 'companion_reference_tokens.dart';

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
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Padding(
        padding: const EdgeInsets.only(
          left:
              CompanionReferenceTokens.avatarSize +
              CompanionReferenceTokens.avatarGap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showRetry)
              _IconAction(
                icon: Icons.auto_awesome_outlined,
                label: CompanionCopy.regenerateAction,
                onTap: onRegenerate,
              ),
            if (saveDraft != null) _FavoriteIconAction(draft: saveDraft!),
            _IconAction(
              icon: Icons.copy_rounded,
              label: CompanionCopy.copyAction,
              onTap: () => InsightCopyAction.copy(context, message.content),
            ),
            if (showSpeak)
              _IconAction(
                icon: Icons.volume_up_outlined,
                label: CompanionCopy.speakAction,
                onTap: () => onSpeak(message.content),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
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
          constraints: const BoxConstraints(
            minWidth: OraclyA11y.minTouchTarget,
            minHeight: OraclyA11y.minTouchTarget,
          ),
          child: Icon(
            icon,
            size: 16,
            color: OraclyChrome.goldLight.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _FavoriteIconAction extends ConsumerWidget {
  const _FavoriteIconAction({required this.draft});

  final FavoriteMoment draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoriteMomentSavedProvider(draft.id));
    final label = saved ? FavoriteMomentsCopy.unsave : FavoriteMomentsCopy.save;
    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: () async {
          final notifier = ref.read(favoriteMomentsProvider.notifier);
          if (saved) {
            await notifier.remove(draft.id);
          } else {
            await notifier.save(draft);
          }
        },
        child: SizedBox(
          width: OraclyA11y.minTouchTarget,
          height: OraclyA11y.minTouchTarget,
          child: Center(
            child: CompanionGoldLineIcon(
              kind: CompanionLineIconKind.heart,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
