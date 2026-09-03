/// Day separator -- Today with soft gold hairlines.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';

class CompanionDaySeparator extends StatelessWidget {
  const CompanionDaySeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 0.7,
                    color: OraclyChrome.gold.withValues(alpha: 0.22),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OraclyChrome.gold.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              CompanionCopy.dayToday,
              style: ReadingTypography.micro(
                color: OraclyChrome.cream.withValues(alpha: 0.55),
              ).copyWith(fontSize: 11, letterSpacing: 0.4),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OraclyChrome.gold.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 0.7,
                    color: OraclyChrome.gold.withValues(alpha: 0.22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
