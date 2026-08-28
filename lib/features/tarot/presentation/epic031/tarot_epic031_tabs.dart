/// EPIC-031 — Selected gold-bordered dark pill; others plain text.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import 'tarot_epic031_spec.dart';

class TarotEpic031Tabs extends StatelessWidget {
  const TarotEpic031Tabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TarotEpic031Category selected;
  final ValueChanged<TarotEpic031Category> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TarotEpic031Spec.tabHeight,
      child: Row(
        children: [
          for (var i = 0; i < TarotEpic031Category.values.length; i++) ...[
            if (i > 0) SizedBox(width: TarotEpic031Spec.tabGap),
            Expanded(
              child: _TabPill(
                label: TarotEpic031Category.values[i].label,
                selected: TarotEpic031Category.values[i] == selected,
                onTap: () => onSelected(TarotEpic031Category.values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? OraclyChrome.goldHighlight.withValues(alpha: 0.98)
        : AppColors.goldDeep.withValues(alpha: 0.62);

    return OraclyPressable(
      onTap: onTap,
      borderRadius: TarotEpic031Spec.tabRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: TarotEpic031Spec.tabHeight,
        decoration: BoxDecoration(
          borderRadius: TarotEpic031Spec.tabRadius,
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    OraclyChrome.violet.withValues(alpha: 0.28),
                    OraclyChrome.deepNavy.withValues(alpha: 0.88),
                  ],
                )
              : null,
          border: selected
              ? Border.all(
                  color: OraclyChrome.goldPrimary.withValues(alpha: 0.62),
                  width: AppBorderWidth.thin,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: OraclyChrome.goldHighlight
                        .withValues(alpha: OraclyChrome.glowSoft),
                    blurRadius: 10,
                    spreadRadius: -1,
                  ),
                  BoxShadow(
                    color: OraclyChrome.violet
                        .withValues(alpha: OraclyChrome.glowSoft),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: TarotEpic031Spec.tabLetterSpacing,
            fontSize: TarotEpic031Spec.tabFontSize,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}
