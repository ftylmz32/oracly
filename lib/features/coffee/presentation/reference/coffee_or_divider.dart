/// Quiet gold OR between camera and gallery.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/coffee_copy.dart';

class CoffeeOrDivider extends StatelessWidget {
  const CoffeeOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final gold = OraclyChrome.goldLight.withValues(alpha: 0.48);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _shortRule(gold),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            child: Text(
              CoffeeCopy.orChoice,
              style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
                letterSpacing: 2.2,
                color: OraclyChrome.cream.withValues(alpha: 0.78),
              ),
            ),
          ),
          _shortRule(gold, reverse: true),
        ],
      ),
    );
  }

  Widget _shortRule(Color gold, {bool reverse = false}) {
    final diamond = Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
    );
    final line = Container(width: 28, height: 0.7, color: gold);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reverse ? [line, diamond] : [diamond, line],
    );
  }
}
