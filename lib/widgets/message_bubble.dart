import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/reading_typography.dart';
import '../features/ai/presentation/widgets/conversation_message_entrance.dart';
import 'oracly_icon.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.animate = true,
  });

  final String message;
  final bool isUser;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.sm,
                top: AppSpacing.sm,
              ),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                boxShadow: AppShadows.iconGlow,
              ),
              child: const Center(
                child: OraclyIcon(Icons.auto_awesome, size: 16),
              ),
            ),
          Container(
            margin: EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUser
                    ? [
                        AppColors.primary.withValues(alpha: 0.85),
                        AppColors.primaryLight.withValues(alpha: 0.75),
                      ]
                    : [
                        AppColors.card.withValues(alpha: 0.95),
                        AppColors.backgroundSecondary.withValues(alpha: 0.9),
                      ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: AppRadius.lg.topLeft,
                topRight: AppRadius.lg.topRight,
                bottomLeft: Radius.circular(
                  isUser ? AppRadius.lgValue + AppSpacing.xs : AppRadius.xsValue,
                ),
                bottomRight: Radius.circular(
                  isUser ? AppRadius.xsValue : AppRadius.lgValue + AppSpacing.xs,
                ),
              ),
              border: Border.all(
                color: isUser
                    ? AppColors.primaryLight.withValues(alpha: 0.3)
                    : AppColors.gold.withValues(alpha: 0.2),
              ),
              boxShadow: AppShadows.soft,
            ),
            child: Text(
              message,
              style: ReadingTypography.body(
                color: isUser ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    if (!animate) return bubble;

    return ConversationMessageEntrance(child: bubble);
  }
}
