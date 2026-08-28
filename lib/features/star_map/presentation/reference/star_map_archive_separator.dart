/// Quiet brass hairline between archive chapters.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/craftsmanship_rhythm.dart';
import 'star_map_reference_tokens.dart';

class StarMapArchiveSeparator extends StatelessWidget {
  const StarMapArchiveSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final brass = StarMapReferenceTokens.brassGlow;
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
                brass.withValues(alpha: 0.34),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
