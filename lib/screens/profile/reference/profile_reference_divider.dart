/// Quiet brass hairline between Profile acts.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/craftsmanship_rhythm.dart';

class ProfileReferenceDivider extends StatelessWidget {
  const ProfileReferenceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: CraftsmanshipRhythm.betweenActs * 0.28,
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                OraclyChrome.gold.withValues(alpha: 0.34),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
