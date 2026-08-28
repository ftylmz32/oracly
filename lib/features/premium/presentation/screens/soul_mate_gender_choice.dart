/// Three quiet presence choices — they change the painted figure, not a score.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/soul_mate_copy.dart';
import '../../services/soul_mate_draw_port.dart';

class SoulMateGenderChoice extends StatelessWidget {
  const SoulMateGenderChoice({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SoulMateGenderPref? selected;
  final ValueChanged<SoulMateGenderPref?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _chip(SoulMateGenderPref.feminine, SoulMateCopy.genderFeminine),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _chip(
            SoulMateGenderPref.masculine,
            SoulMateCopy.genderMasculine,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: _chip(null, SoulMateCopy.genderHint)),
      ],
    );
  }

  Widget _chip(SoulMateGenderPref? value, String label) {
    final on = selected == value;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      child: OraclyGlassCard(
        selected: on,
        premium: on,
        elevated: !on,
        glowStrength: on ? 1.12 : 0.64,
        onTap: () => onSelected(value),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
