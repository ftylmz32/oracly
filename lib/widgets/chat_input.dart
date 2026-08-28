import 'package:flutter/material.dart';

import '../core/copy/conversation_copy.dart';
import '../core/design_system/app_layout.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';
import 'oracly_icon.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          AppLayout.scrollBottomInset(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.92),
          border: Border(
            top: BorderSide(color: AppColors.gold.withValues(alpha: 0.15)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.xl,
                  color: AppColors.card.withValues(alpha: 0.85),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: AppShadows.soft,
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: AppTextStyles.body.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: ConversationCopy.inputHint,
                    hintStyle: AppTextStyles.subtitle.copyWith(fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              enabled: enabled,
              label: ConversationCopy.askOr,
              child: GestureDetector(
                onTap: enabled ? onSend : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.9),
                        AppColors.goldLight.withValues(alpha: 0.85),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.goldLight.withValues(alpha: 0.5),
                    ),
                    boxShadow: AppShadows.goldGlow,
                  ),
                  child: const Center(
                    child: OraclyIcon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
