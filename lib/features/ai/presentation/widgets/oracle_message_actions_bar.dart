/// OR-1190 — Oracle message actions: copy, share, regenerate, favorite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/insight_copy/insight_copy_action.dart';
import '../../../../core/insight_copy/insight_copy_strings.dart';
import '../../../../core/insight_copy/insight_copy_text.dart';
import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../domain/models/ai_message.dart';

class OracleMessageActionsBar extends StatelessWidget {
  const OracleMessageActionsBar({
    super.key,
    required this.message,
    required this.isFavorite,
    this.onRegenerate,
    this.onToggleFavorite,
  });

  final AIMessage message;
  final bool isFavorite;
  final VoidCallback? onRegenerate;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    if (!message.isAssistant || message.isStreaming) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: Icons.copy_rounded,
          tooltip: InsightCopyStrings.action,
          onTap: () => InsightCopyAction.copy(context, message.content),
        ),
        _ActionIcon(
          icon: Icons.share_rounded,
          tooltip: 'Paylaş',
          onTap: () => _copy(
            context,
            'OR Tarot Rehberliği\n\n${InsightCopyText.clean(message.content)}',
            'Paylaşım metni kopyalandı',
          ),
        ),
        if (onRegenerate != null)
          _ActionIcon(
            icon: Icons.refresh_rounded,
            tooltip: 'Yeniden oluştur',
            onTap: onRegenerate,
          ),
        _ActionIcon(
          icon: isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          tooltip: isFavorite ? 'Favoriden çıkar' : 'Favorile',
          onTap: onToggleFavorite,
          active: isFavorite,
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text, String snack) {
    Clipboard.setData(ClipboardData(text: text));
    OraclySnackBar.show(context, message: snack);
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      label: tooltip,
      borderRadius: BorderRadius.circular(8),
      child: OraclyA11y.ensureMinTouch(
        child: Icon(
          icon,
          size: 20,
          color: active
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: OraclyA11y.iconGoldIdle),
        ),
      ),
    );
  }
}
