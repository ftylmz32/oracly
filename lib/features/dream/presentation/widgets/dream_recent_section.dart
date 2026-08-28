/// Reference dream screen — Son Rüyalarım list rows.
library;

import 'package:flutter/material.dart';

import '../../../../core/l10n/oracly_format.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/oracly_signature_motifs.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../models/dream.dart';
import 'dream_reference_hero.dart';

/// Recent dreams section — thumbnail, title, date, chevron.
class DreamRecentSection extends StatelessWidget {
  const DreamRecentSection({
    super.key,
    required this.dreams,
    this.onDreamTap,
  });

  final List<Dream> dreams;
  final ValueChanged<Dream>? onDreamTap;

  static const String title = 'Son Rüyalarım';

  @override
  Widget build(BuildContext context) {
    if (dreams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.72),
            letterSpacing: 2.8,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: AppSpacing.md),
        for (var i = 0; i < dreams.length && i < 5; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.sm),
          _DreamRecentRow(
            dream: dreams[i],
            onTap: onDreamTap != null ? () => onDreamTap!(dreams[i]) : null,
          ),
        ],
      ],
    );
  }
}

class _DreamRecentRow extends StatefulWidget {
  const _DreamRecentRow({
    required this.dream,
    this.onTap,
  });

  final Dream dream;
  final VoidCallback? onTap;

  @override
  State<_DreamRecentRow> createState() => _DreamRecentRowState();
}

class _DreamRecentRowState extends State<_DreamRecentRow> {
  bool _pressed = false;

  String get _title {
    final text = widget.dream.narrative.trim();
    if (text.isEmpty) return 'İsimsiz rüya';
    final line = text.split(RegExp(r'\n')).first.trim();
    return line.length > 48 ? '${line.substring(0, 48)}…' : line;
  }

  String get _dateLabel => OraclyFormat.dateNumeric(widget.dream.recordedAt);

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      borderRadius: AppRadius.lg,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          color: AppColors.surface.withValues(alpha: _pressed ? 0.42 : 0.32),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.18),
            width: AppBorderWidth.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleGlow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const DreamRecentThumbnail(),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    _dateLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted.withValues(alpha: 0.72),
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.goldLight.withValues(alpha: 0.72),
            ),
          ],
        ),
      ),
    );
  }
}
