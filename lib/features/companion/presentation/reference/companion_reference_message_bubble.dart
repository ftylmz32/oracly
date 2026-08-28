/// Message turns — spacious OR reading · warm user notes.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_flow_text.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_living_core.dart';
import 'companion_or_presence.dart';
import 'companion_or_visual.dart';
import 'companion_reference_bubble_surface.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceMessageBubble extends StatelessWidget {
  const CompanionReferenceMessageBubble({
    super.key,
    required this.message,
    this.live = false,
  });

  final AIMessage message;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxFactor = isUser
        ? CompanionReferenceTokens.userBubbleMaxFactor
        : CompanionReferenceTokens.orBubbleMaxFactor;
    final role = isUser ? CompanionCopy.messageYou : CompanionCopy.messageOr;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        container: true,
        label: role,
        value: message.content,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * maxFactor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ExcludeSemantics(
                    child: CompanionOrLivingCore(
                      size: CompanionReferenceTokens.orMark + 6,
                      compact: true,
                      breathe: live &&
                          CompanionOrVisual.presenceOf(context) !=
                              CompanionOrPresence.idle,
                      presence: live
                          ? CompanionOrVisual.presenceOf(context)
                          : CompanionOrPresence.idle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: ExcludeSemantics(
                  child: CompanionReferenceBubbleSurface(
                    isUser: isUser,
                    child: Padding(
                      padding: isUser
                          ? CompanionReferenceTokens.userMessagePadding
                          : CompanionReferenceTokens.orMessagePadding,
                      child: ReadingFlowText(
                        text: message.content,
                        style: isUser
                            ? AppTextStyles.bodyMedium.copyWith(
                                color: OraclyChrome.cream
                                    .withValues(alpha: 0.96),
                                height: CraftsmanshipRhythm.bodyLineHeight,
                                letterSpacing: 0.12,
                                fontSize: 15,
                              )
                            : ReadingTypography.body(
                                color: OraclyChrome.cream.withValues(
                                  alpha: OraclyA11y.secondaryCream,
                                ),
                              ).copyWith(
                                height: CraftsmanshipRhythm.bodyLineHeight,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
























