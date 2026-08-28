/// Thin gold progress track — never Material LinearProgressIndicator.
library;

import 'package:flutter/material.dart';

import 'oracly_chrome.dart';

class OraclyProgressBar extends StatelessWidget {
  const OraclyProgressBar({
    super.key,
    required this.value,
    this.height = 3,
  });

  /// 0..1
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(t * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: OraclyChrome.midnight.withValues(alpha: 0.55),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OraclyChrome.gold.withValues(alpha: 0.55),
                        OraclyChrome.goldLight.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
