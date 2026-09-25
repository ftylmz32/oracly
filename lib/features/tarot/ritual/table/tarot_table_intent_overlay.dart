/// Compact intention chips on the table — no navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/oracly_brand_signature.dart';
import 'tarot_table_intent_catalogue.dart';
import 'tarot_table_intent_chip.dart';

export 'tarot_table_intent_catalogue.dart';

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
            height: OraclyA11y.minTouchTarget,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: TableIntentCatalogue.options.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final o = TableIntentCatalogue.options[i];
                return TarotTableIntentChip(
                  option: o,
                  selected: selectedId == o.id,
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
