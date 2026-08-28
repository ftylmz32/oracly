/// Compact intention chips on the table — no navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/oracly_brand_signature.dart';

class TableIntentOption {
  const TableIntentOption({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

abstract final class TableIntentCatalogue {
  TableIntentCatalogue._();

  static const options = [
    TableIntentOption(id: 'love', title: 'Aşk', icon: Icons.favorite_rounded),
    TableIntentOption(
      id: 'career',
      title: 'Kariyer',
      icon: Icons.work_outline_rounded,
    ),
    TableIntentOption(
      id: 'future',
      title: 'Gelecek',
      icon: Icons.auto_awesome_rounded,
    ),
    TableIntentOption(
      id: 'inner',
      title: 'İç Dünyam',
      icon: Icons.nightlight_round,
    ),
    TableIntentOption(
      id: 'custom',
      title: 'Kendi Sorumu Sor',
      icon: Icons.edit_outlined,
    ),
  ];
}

class TarotTableIntentOverlay extends StatelessWidget {
  const TarotTableIntentOverlay({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.receded = false,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final bool receded;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: OraclySignatureMotion.pressRelease,
      opacity: receded ? 0 : 1,
      child: AnimatedSlide(
        duration: OraclySignatureMotion.pressRelease,
        offset: receded ? const Offset(0, -0.15) : Offset.zero,
        child: IgnorePointer(
          ignoring: receded,
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: TableIntentCatalogue.options.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final o = TableIntentCatalogue.options[i];
                final selected = selectedId == o.id;
                return _Chip(
                  option: o,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(o.id);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TableIntentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: OraclySignatureMotion.press,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? const Color(0xFF2A1847).withValues(alpha: 0.85)
              : const Color(0xFF0C0916).withValues(alpha: 0.72),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: selected ? 0.7 : 0.28),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF9B6DFF).withValues(alpha: 0.28),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, size: 14, color: AppColors.gold),
            const SizedBox(width: 6),
            Text(
              option.title,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
