/// Astrology wait — subtle celestial breath around the instrument.
library;

import 'package:flutter/material.dart';

import '../../theme/oracly_quiet_motion.dart';
import '../oracly_chrome.dart';

class LoadingStageAstrologyAura extends StatefulWidget {
  const LoadingStageAstrologyAura({super.key, required this.child});

  final Widget child;

  @override
  State<LoadingStageAstrologyAura> createState() =>
      _LoadingStageAstrologyAuraState();
}

class _LoadingStageAstrologyAuraState extends State<LoadingStageAstrologyAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.5);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = _breath.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: OraclyChrome.gold.withValues(alpha: 0.08 + t * 0.10),
                blurRadius: 28 + t * 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: OraclyChrome.violet.withValues(alpha: 0.10 + t * 0.08),
                blurRadius: 40,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
