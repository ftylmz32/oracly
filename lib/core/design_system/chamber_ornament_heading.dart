/// Centered gold chapter title with a ceremonial hairline.
library;

import 'package:flutter/material.dart';

import '../theme/reading_typography.dart';
import 'oracly_chrome.dart';

class ChamberOrnamentHeading extends StatelessWidget {
  const ChamberOrnamentHeading({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          const _GoldFlute(),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
              letterSpacing: 2.2,
              color: OraclyChrome.goldLight.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 8),
          const _GoldFlute(),
        ],
      ),
    );
  }
}

class _GoldFlute extends StatelessWidget {
  const _GoldFlute();

  @override
  Widget build(BuildContext context) {
    final gold = OraclyChrome.goldLight.withValues(alpha: 0.55);
    return Row(
      children: [
        _diamond(gold),
        Expanded(child: Container(height: 0.7, color: gold)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _diamond(gold, size: 5),
        ),
        Expanded(child: Container(height: 0.7, color: gold)),
        _diamond(gold),
      ],
    );
  }

  Widget _diamond(Color color, {double size = 4}) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(width: size, height: size, color: color),
    );
  }
}
