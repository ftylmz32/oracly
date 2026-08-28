/// Editorial result title — quiet after the cup, never a badge.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/coffee_copy.dart';

class CoffeeResultTitle extends StatelessWidget {
  const CoffeeResultTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: CraftsmanshipRhythm.afterTitle),
      child: Column(
        children: [
          Text(
            CoffeeCopy.overallTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.title(),
          ),
          SizedBox(height: CraftsmanshipRhythm.afterTitle),
          Text(
            CoffeeCopy.overallSubtitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.opening(
              color: OraclyChrome.cream.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}
