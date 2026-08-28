/// Virtualized OR message list — keys, cacheExtent, repaint isolation.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../../tarot/revisit/tarot_revisit_context.dart';
import '../../services/companion_followup_chips.dart';
import 'companion_reference_thread_item.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceThreadList extends StatelessWidget {
  const CompanionReferenceThreadList({
    super.key,
    required this.scrollController,
    required this.visible,
    required this.lastOrId,
    required this.showActions,
    required this.onSpeak,
    required this.onRegenerate,
    required this.allowSpeak,
    this.revisit,
    this.onFollowUp,
    this.hasReadingContext = false,
    this.lastUserMessage = '',
  });

  final ScrollController scrollController;
  final List<AIMessage> visible;
  final String? lastOrId;
  final bool showActions;
  final ValueChanged<String> onSpeak;
  final VoidCallback onRegenerate;
  final bool allowSpeak;
  final TarotRevisitContext? revisit;
  final ValueChanged<String>? onFollowUp;
  final bool hasReadingContext;
  final String lastUserMessage;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      // Prefetch nearby bubbles for long threads without rebuilding offstage work.
      // ignore: deprecated_member_use
      cacheExtent: 600,
      padding: EdgeInsets.fromLTRB(
        CompanionReferenceTokens.screenHorizontal,
        AppSpacing.s12,
        CompanionReferenceTokens.screenHorizontal,
        AppSpacing.s12,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, _) =>
          SizedBox(height: CompanionReferenceTokens.messageGap),
      itemBuilder: (context, index) {
        final message = visible[index];
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: CompanionReferenceThreadItem(
            message: message,
            isLiveOr: message.id == lastOrId,
            showActions: showActions,
            onSpeak: onSpeak,
            onRegenerate: onRegenerate,
            allowSpeak: allowSpeak,
            revisit: message.id == lastOrId ? revisit : null,
            onFollowUp: message.id == lastOrId ? onFollowUp : null,
            followUpChips: message.id == lastOrId && onFollowUp != null
                ? CompanionFollowUpChips.forTurn(
                    lastUserMessage: lastUserMessage,
                    hasReadingContext: hasReadingContext,
                  )
                : const [],
          ),
        );
      },
    );
  }
}
