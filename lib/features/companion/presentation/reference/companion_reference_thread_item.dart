/// One conversation turn — bubble + useful last-OR actions.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/oracly_reduced_motion.dart';
import 'companion_message_entrance.dart';
import '../../../../features/tarot/revisit/tarot_revisit_context.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_message_actions.dart';
import 'companion_reference_message_bubble.dart';
import 'companion_reference_prompts.dart';
import '../../../../core/revisit/widgets/discovery_revisit_card.dart';

class CompanionReferenceThreadItem extends StatelessWidget {
  const CompanionReferenceThreadItem({
    super.key,
    required this.message,
    required this.isLiveOr,
    required this.showActions,
    required this.onSpeak,
    required this.onRegenerate,
    required this.allowSpeak,
    this.revisit,
    this.onFollowUp,
    this.followUpChips = const [],
  });

  final AIMessage message;
  final bool isLiveOr;
  final bool showActions;
  final ValueChanged<String> onSpeak;
  final VoidCallback onRegenerate;
  final bool allowSpeak;
  final TarotRevisitContext? revisit;
  final ValueChanged<String>? onFollowUp;
  final List<String> followUpChips;

  @override
  Widget build(BuildContext context) {
    final bubble = CompanionReferenceMessageBubble(
      message: message,
      live: isLiveOr,
    );
    final row = isLiveOr && showActions
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bubble,
              CompanionOrMessageActions(
                message: message,
                onSpeak: onSpeak,
                onRegenerate: onRegenerate,
                showSpeak: allowSpeak,
                saveDraft: FavoriteMomentFactory.companion(message),
              ),
              if (onFollowUp != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tip in followUpChips)
                      CompanionPromptChip(
                        label: tip,
                        light: true,
                        onTap: () => onFollowUp!(tip),
                      ),
                  ],
                ),
              ],
              if (revisit != null) DiscoveryRevisitCard(revisit: revisit!),
            ],
          )
        : bubble;
    if (OraclyReducedMotion.of(context)) return row;
    return CompanionMessageEntrance(
      key: ValueKey('enter_${message.id}'),
      kind: message.isUser
          ? CompanionMessageEntranceKind.user
          : CompanionMessageEntranceKind.assistant,
      child: row,
    );
  }
}
