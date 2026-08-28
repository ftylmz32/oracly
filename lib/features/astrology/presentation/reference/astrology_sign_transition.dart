/// Soft sign-context crossfade — fade + scale, never abrupt replace.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_motion.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';

class AstrologySignTransition extends StatelessWidget {
  const AstrologySignTransition({
    super.key,
    required this.signId,
    required this.child,
    this.duration = AppMotionDuration.slow,
    this.scaleFrom = 0.985,
  });

  final String signId;
  final Widget child;
  final Duration duration;
  final double scaleFrom;

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    if (still) {
      return KeyedSubtree(key: ValueKey(signId), child: child);
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotionCurve.easeOut,
      switchOutCurve: AppMotionCurve.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ...previous,
          ?current,
        ],
      ),
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        );
        final scale = Tween<double>(begin: scaleFrom, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
          ),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(signId),
        child: child,
      ),
    );
  }
}
