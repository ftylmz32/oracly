/// OR-1190 — Oracle message actions: copy, share, regenerate, favorite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/ui/oracly_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
          tooltip: 'Kopyala',
          onTap: () => _copy(context, message.content, 'Mesaj kopyalandı'),
        ),
        _ActionIcon(
          icon: Icons.share_rounded,
          tooltip: 'Paylaş',
          onTap: () => _copy(
            context,
            'OR Tarot Rehberliği\n\n${message.content}',
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
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: AppSpacing.md),
      color: active
          ? AppColors.gold
          : AppColors.gold.withValues(alpha: 0.65),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.all(AppSpacing.xs),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
