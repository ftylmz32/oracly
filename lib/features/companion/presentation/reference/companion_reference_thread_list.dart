/// Virtualized OR message list -- hero, day separator, then turns.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../../tarot/revisit/tarot_revisit_context.dart';
import '../../services/companion_followup_chips.dart';
import 'companion_day_separator.dart';
import 'companion_luna_intro_card.dart';
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

  static const _headerCount = 2;

  @override
  Widget build(BuildContext context) {
    final short = CompanionReferenceTokens.isShortViewport(context);
    final total = visible.length + _headerCount;
    return ListView.separated(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      // ignore: deprecated_member_use
      cacheExtent: 600,
      padding: EdgeInsets.fromLTRB(
        CompanionReferenceTokens.screenHorizontal,
        AppSpacing.s8,
        CompanionReferenceTokens.screenHorizontal,
        AppSpacing.s12,
      ),
      itemCount: total,
      separatorBuilder: (context, index) {
        if (index < _headerCount - 1) {
          return SizedBox(height: CompanionReferenceTokens.daySeparatorGap);
        }
        if (index == _headerCount - 1) {
          return const SizedBox(height: 4);
        }
        return SizedBox(height: CompanionReferenceTokens.messageGap);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return CompanionLunaIntroCard(compact: short);
        }
        if (index == 1) {
          return const CompanionDaySeparator();
        }
        final message = visible[index - _headerCount];
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
