/// Quiet gold hairline between private reading acts.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';

class PalmResultSeparator extends StatelessWidget {
  const PalmResultSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: CraftsmanshipRhythm.betweenActs * 0.35,
      ),
      child: Center(
        child: Container(
          width: 42,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                OraclyChrome.gold.withValues(alpha: 0.28),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
