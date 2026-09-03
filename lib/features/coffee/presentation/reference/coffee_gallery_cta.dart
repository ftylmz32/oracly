/// Gold outline gallery CTA - secondary to the filled photo pill.
library;

import 'package:flutter/material.dart';

import '../../../../core/accessibility/oracly_a11y.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../copy/coffee_copy.dart';

class CoffeeGalleryCta extends StatelessWidget {
  const CoffeeGalleryCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      label: CoffeeCopy.galleryLabel,
      borderRadius: OraclyChrome.pillRadius,
      glowShift: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: OraclyA11y.minTouchTarget,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.pillRadius,
            color: OraclyChrome.midnight.withValues(alpha: 0.28),
            border: Border.all(
              color: OraclyChrome.gold.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: AppLayout.referencePrimaryButtonPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.photo_outlined,
                    size: AppLayout.referenceIconSize,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    CoffeeCopy.galleryLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OraclyChrome.ctaLabel(size: 15).copyWith(
                      color: OraclyChrome.goldLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
