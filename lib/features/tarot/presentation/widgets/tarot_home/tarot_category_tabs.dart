/// Reference tarot home — four category tabs below the app bar.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../shared/widgets/oracly_pressable.dart';

/// Fal category identifiers matching the reference tabs.
enum TarotFalCategory {
  daily('Günlük Fal'),
  love('Aşk'),
  career('Kariyer'),
  general('Genel');

  const TarotFalCategory(this.label);

  final String label;
}

/// Horizontal row of four rounded category pills — gold when selected.
class TarotCategoryTabs extends StatelessWidget {
  const TarotCategoryTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TarotFalCategory selected;
  final ValueChanged<TarotFalCategory> onSelected;

  static const double tabHeight = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tabHeight,
      child: Row(
        children: [
          for (var i = 0; i < TarotFalCategory.values.length; i++) ...[
            if (i > 0) SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CategoryTab(
                label: TarotFalCategory.values[i].label,
                selected: TarotFalCategory.values[i] == selected,
                onTap: () => onSelected(TarotFalCategory.values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTab extends StatefulWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final goldAlpha = selected ? 0.42 : 0.18;
    final bgAlpha = selected ? 0.38 : 0.22;
    final textColor = selected
        ? AppColors.goldLight.withValues(alpha: 0.94)
        : AppColors.textSecondary.withValues(alpha: 0.72);

    return OraclyPressable(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      borderRadius: AppRadius.round,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: TarotCategoryTabs.tabHeight,
        decoration: BoxDecoration(
          borderRadius: AppRadius.round,
          color: AppColors.surface.withValues(alpha: bgAlpha),
          border: Border.all(
            color: AppColors.gold.withValues(
              alpha: _pressed && selected ? goldAlpha + 0.08 : goldAlpha,
            ),
            width: selected ? AppBorderWidth.thin : AppBorderWidth.hairline,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.goldGlow.withValues(alpha: 0.16),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelMedium.copyWith(
            color: textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.15,
            fontSize: 12,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
