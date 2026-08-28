/// OR-1190 / RC-002 — Empty state for oracle conversation.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/conversation_copy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'oracle_avatar.dart';

class OracleConversationEmptyState extends StatelessWidget {
  const OracleConversationEmptyState({
    super.key,
    this.title,
    this.body,
  });

  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final heading = title ?? ConversationCopy.oracleEmptyTitle;
    final copy = body ?? ConversationCopy.oracleEmptyBody;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const OracleAvatar(size: 64, showGlow: true),
        SizedBox(height: AppSpacing.xl),
        Text(
          heading,
          textAlign: TextAlign.center,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.goldLight,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            copy,
            textAlign: TextAlign.center,
            style: ReadingTypography.body(
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
