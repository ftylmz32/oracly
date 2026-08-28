/// OR-1190 — Premium glass input for oracle conversation.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/copy/conversation_copy.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class OracleConversationInput extends StatelessWidget {
  const OracleConversationInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  static String get placeholder => ConversationCopy.oracleInputHint;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppLayout.scrollBottomInset(context),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.xl,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.xl,
                color: AppColors.surface.withValues(alpha: 0.72),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  width: AppBorderWidth.hairline,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: enabled ? (_) => onSend() : null,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    _SendButton(onTap: enabled ? onSend : null),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1,
        duration: CraftsmanshipRhythm.press,
        child: Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.95),
                AppColors.goldLight.withValues(alpha: 0.88),
              ],
            ),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.55),
            ),
            boxShadow: AppShadows.goldGlow,
          ),
          child: Icon(
            Icons.arrow_upward_rounded,
            size: AppSpacing.lg,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
