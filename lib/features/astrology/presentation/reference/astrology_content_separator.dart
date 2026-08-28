/// Shared gold hairline — quiet section separator inside content cards.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';

class AstrologyContentSeparator extends StatelessWidget {
  const AstrologyContentSeparator({
    super.key,
    this.vertical = 10,
  });

  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: SizedBox(
        height: 8,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    OraclyChrome.gold.withValues(alpha: 0.0),
                    OraclyChrome.goldLight.withValues(alpha: 0.55),
                    OraclyChrome.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: const SizedBox(height: 0.7, width: double.infinity),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: OraclyChrome.deepNavy.withValues(alpha: 0.85),
                border: Border.all(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.72),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: OraclyChrome.gold.withValues(alpha: 0.28),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const SizedBox(width: 5, height: 5),
            ),
          ],
        ),
      ),
    );
  }
}
