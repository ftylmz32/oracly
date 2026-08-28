/// OR-1110 — Premium AI message bubble with markdown + actions.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/resilience_copy.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../domain/models/ai_message.dart';
import '../../../../core/reading_ux/reading_expand_section.dart';
import '../../../../core/theme/reading_flow_text.dart';
import 'ai_markdown_body.dart';
import 'ai_message_actions.dart';
import 'oracle_avatar.dart';
import 'streaming_text.dart';

class AIMessageBubble extends StatelessWidget {
  const AIMessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onRetry,
    this.showAvatar = true,
    this.useMarkdown = true,
  });

  final AIMessage message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;
  final bool showAvatar;
  final bool useMarkdown;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && showAvatar) ...[
            const OracleAvatar(size: 32, showGlow: false),
            SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUser
                          ? [
                              AppColors.purple.withValues(alpha: 0.52),
                              AppColors.purpleDark.withValues(alpha: 0.62),
                            ]
                          : [
                              AppColors.surfaceElevated
                                  .withValues(alpha: 0.94),
                              AppColors.surface.withValues(alpha: 0.88),
                            ],
                    ),
                    borderRadius: AppRadius.lg,
                    border: Border.all(
                      color: AppColors.gold.withValues(
                        alpha: isUser ? 0.22 : 0.28,
                      ),
                      width: AppBorderWidth.hairline,
                    ),
                  ),
                  child: Padding(
                    padding: AppSpacing.card,
                    child: _Body(
                      message: message,
                      isUser: isUser,
                      useMarkdown: useMarkdown,
                    ),
                  ),
                ),
                if (!isUser && message.status == AIMessageStatus.completed) ...[
                  SizedBox(height: AppSpacing.xs),
                  AIMessageActions(
                    message: message,
                    onRegenerate: onRegenerate,
                    onRetry: onRetry,
                    onCite: message.citations.isNotEmpty ? () {} : null,
                  ),
                ],
                if (message.citations.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: message.citations
                        .map(
                          (c) => Chip(
                            label: Text(
                              '[${c.label}] ${c.source}',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontSize: 10,
                              ),
                            ),
                            backgroundColor:
                                AppColors.surface.withValues(alpha: 0.6),
                            side: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.2),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser && showAvatar) ...[
            SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.purpleDark,
              child: Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.goldLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.message,
    required this.isUser,
    required this.useMarkdown,
  });

  final AIMessage message;
  final bool isUser;
  final bool useMarkdown;

  @override
  Widget build(BuildContext context) {
    final style = ReadingTypography.body(
      color: isUser ? AppColors.textPrimary : AppColors.textSecondary,
    );

    if (message.isStreaming) {
      return StreamingText(
        text: message.content,
        isStreaming: true,
        style: style,
      );
    }

    if (message.hasError) {
      return Text(
        AiErrorSanitizer.guard(
          message.errorMessage,
          fallback: ResilienceCopy.aiUnavailable,
        ),
        style: style.copyWith(
          color: const Color(0xFFC9A46C).withValues(alpha: 0.92),
        ),
      );
    }

    if (useMarkdown && !isUser) {
      if (ReadingExpandSection.isLong(message.content)) {
        return ReadingExpandSection(body: message.content);
      }
      return AIMarkdownBody(markdown: message.content, textStyle: style);
    }

    if (!isUser && ReadingExpandSection.isLong(message.content)) {
      return ReadingExpandSection(body: message.content);
    }

    return ReadingFlowText(text: message.content, style: style);
  }
}
