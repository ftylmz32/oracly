/// Pure HH:MM:SS visual -- large labeled digit blocks on a dark glass card.
/// No timers, no state; a stateless function of [remaining].
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../copy/reading_live_copy.dart';

class ReadingWaitCountdownFace extends StatelessWidget {
  const ReadingWaitCountdownFace({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final total = remaining.isNegative ? Duration.zero : remaining;
    final totalSeconds = total.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s24,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xl,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OraclyChrome.deepNavy,
            OraclyChrome.midnight,
          ],
        ),
        border: Border.all(
          color: OraclyChrome.goldLight.withValues(
            alpha: OraclyChrome.borderEmphasis,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.violet.withValues(alpha: OraclyChrome.glowSoft),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      // Scales down as one unit on narrow devices rather than risking a
      // pixel overflow -- the numbers stay legible and centered instead of
      // wrapping or clipping.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountdownUnit(value: hours, label: ReadingLiveCopy.hoursLabel),
            const _CountdownColon(),
            _CountdownUnit(
              value: minutes,
              label: ReadingLiveCopy.minutesLabel,
            ),
            const _CountdownColon(),
            _CountdownUnit(
              value: seconds,
              label: ReadingLiveCopy.secondsLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          semanticsLabel: '$value $label',
          style: TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: OraclyChrome.goldLight,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: OraclyChrome.cream.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _CountdownColon extends StatelessWidget {
  const _CountdownColon();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(
          ':',
          style: TextStyle(
            fontFamily: AppTypography.bodyFontFamily,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: OraclyChrome.goldLight.withValues(alpha: 0.55),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
