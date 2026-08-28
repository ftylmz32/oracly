/// Subtle ORACLY emblem well for the OR gateway card.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';

class HomeReferenceOrEmblemWell extends StatelessWidget {
  const HomeReferenceOrEmblemWell({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: OraclyChrome.violet.withValues(alpha: 0.28),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.42),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.violet.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 26,
          color: OraclyChrome.goldLight.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
