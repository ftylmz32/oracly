/// Reference tarot home — Geçmiş Fallarım vertical history rows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/providers/app_providers.dart';
import '../../../../../core/design_system/app_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../utils/reading_history_mapper.dart';
import 'oracly_sacred_identity.dart';

/// History list — rounded rows with trailing arrow.
class TarotReferenceHistorySection extends ConsumerWidget {
  const TarotReferenceHistorySection({
    super.key,
    this.onViewAll,
    this.onEntryTap,
  });

  final VoidCallback? onViewAll;
  final VoidCallback? onEntryTap;

  static const String title = 'Geçmiş Fallarım';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(readingHistoryProvider);

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
        SizedBox(height: AppLayout.referenceSectionLabelToContent),
        historyAsync.when(
          loading: () => const _HistoryPlaceholder(),
          error: (_, _) => const SizedBox.shrink(),
          data: (readings) {
            if (readings.isEmpty) return const SizedBox.shrink();
            final recent =
                readings.take(3).map(ReadingHistoryMapper.fromModel).toList();
            return Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) SizedBox(height: AppSpacing.sm),
                  _HistoryRow(
                    title: recent[i].typeLabel,
                    subtitle: recent[i].cardName,
                    meta: recent[i].dateLabel,
                    onTap: onEntryTap ?? onViewAll,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HistoryPlaceholder extends StatelessWidget {
  const _HistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: Text(
          'Geçmiş yükleniyor…',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted.withValues(alpha: 0.72),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatefulWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.meta,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onTap;

  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      borderRadius: AppRadius.s20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: AppRadius.s20,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: OraclyTypography.tileTitle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.78),
                      height: 1.35,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.meta,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted.withValues(alpha: 0.68),
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
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
