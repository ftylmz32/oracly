/// OR-1110 — Message action bar (retry, regenerate, copy, cite).
library;

import 'package:flutter/material.dart';

import '../../../../core/insight_copy/insight_copy_action.dart';
import '../../../../core/insight_copy/insight_copy_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../domain/models/ai_message.dart';

class AIMessageActions extends StatelessWidget {
  const AIMessageActions({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onRetry,
    this.onCite,
  });

  final AIMessage message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;
  final VoidCallback? onCite;

  @override
  Widget build(BuildContext context) {
    if (!message.isAssistant) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.copy_rounded,
          tooltip: InsightCopyStrings.action,
          onTap: () => InsightCopyAction.copy(context, message.content),
        ),
        if (onRegenerate != null)
          _ActionIcon(
            icon: Icons.refresh_rounded,
            tooltip: 'Yeniden oluştur',
            onTap: onRegenerate,
          ),
        if (onRetry != null)
          _ActionIcon(
            icon: Icons.replay_rounded,
            tooltip: 'Tekrar dene',
            onTap: onRetry,
          ),
        if (message.citations.isNotEmpty && onCite != null)
          _ActionIcon(
            icon: Icons.menu_book_outlined,
            tooltip: 'Kaynaklar',
            onTap: onCite,
          ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            icon,
            size: AppSpacing.md,
            color: AppColors.gold.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
