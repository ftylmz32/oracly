/// Message turns -- Luna avatar, sanctuary bubbles, readable wrap.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_flow_text.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../copy/companion_copy.dart';
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
    final stamp = DateFormat.Hm().format(message.createdAt.toLocal());
    final avatar = CompanionReferenceTokens.avatarSize;
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
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                ClipOval(
                  child: SizedBox(
                    width: avatar,
                    height: avatar,
                    child: OraclyAssetImage(
                      assetPath: AppAssets.lunaAvatar,
                      fit: BoxFit.cover,
                      fallback: ColoredBox(
                        color: OraclyChrome.violet.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ExcludeSemantics(
                  child: CompanionReferenceBubbleSurface(
                    isUser: isUser,
                    child: Padding(
                      padding: isUser
                          ? CompanionReferenceTokens.userMessagePadding
                          : CompanionReferenceTokens.orMessagePadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReadingFlowText(
                            text: message.content,
                            style: isUser
                                ? AppTextStyles.bodyMedium.copyWith(
                                    color: OraclyChrome.cream.withValues(
                                      alpha: 0.96,
                                    ),
                                    height: 1.42,
                                    fontSize: 13,
                                  )
                                : ReadingTypography.body(
                                    color: OraclyChrome.cream.withValues(
                                      alpha: OraclyA11y.secondaryCream,
                                    ),
                                  ).copyWith(fontSize: 13, height: 1.42),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  stamp,
                                  style: ReadingTypography.micro(
                                    color: OraclyChrome.cream.withValues(
                                      alpha: 0.48,
                                    ),
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.done_all_rounded,
                                    size: 14,
                                    color: OraclyChrome.violet.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
