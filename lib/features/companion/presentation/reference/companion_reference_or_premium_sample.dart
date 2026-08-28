/// Sample OR dialogue — clearly marked example, never user-specific fabrication.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../ai/domain/models/ai_message.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_message_bubble.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceOrPremiumSample extends StatelessWidget {
  const CompanionReferenceOrPremiumSample({super.key});

  static final _epoch = DateTime.utc(2020, 1, 1);

  static List<AIMessage> get turns => [
        AIMessage(
          id: 'preview_u0',
          role: AIMessageRole.user,
          content: CompanionCopy.orPremiumSampleUser0,
          createdAt: _epoch,
        ),
        AIMessage(
          id: 'preview_o0',
          role: AIMessageRole.assistant,
          content: CompanionCopy.orPremiumSampleOr0,
          createdAt: _epoch,
        ),
        AIMessage(
          id: 'preview_u1',
          role: AIMessageRole.user,
          content: CompanionCopy.orPremiumSampleUser1,
          createdAt: _epoch,
        ),
        AIMessage(
          id: 'preview_o1',
          role: AIMessageRole.assistant,
          content: CompanionCopy.orPremiumSampleOr1,
          createdAt: _epoch,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          CompanionCopy.orPremiumSampleLabel,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(
            fontSize: 10,
            color: OraclyChrome.goldLight.withValues(alpha: 0.82),
          ),
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          CompanionCopy.orPremiumSampleNote,
          textAlign: TextAlign.center,
          style: ReadingTypography.bodySmall(
            color: OraclyChrome.cream.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: AppSpacing.s16),
        for (final message in turns) ...[
          CompanionReferenceMessageBubble(message: message),
          SizedBox(height: CompanionReferenceTokens.messageGap * 0.55),
        ],
      ],
    );
  }
}
