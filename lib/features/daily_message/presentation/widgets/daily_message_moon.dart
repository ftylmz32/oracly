/// Small moon + gold halo — quiet ritual accent.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';

class DailyMessageMoon extends StatefulWidget {
  const DailyMessageMoon({super.key, this.size = 36});

  final double size;

  @override
  State<DailyMessageMoon> createState() => _DailyMessageMoonState();
}

class _DailyMessageMoonState extends State<DailyMessageMoon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || OraclyReducedMotion.of(context)) return;
      _breath.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.78, end: 1).animate(
        CurvedAnimation(parent: _breath, curve: Curves.easeInOut),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              OraclyChrome.gold.withValues(alpha: 0.28),
              OraclyChrome.violet.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: OraclyChrome.gold.withValues(alpha: OraclyChrome.glowMedium),
              blurRadius: 14,
            ),
          ],
        ),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Icon(
              Icons.nightlight_round,
              size: widget.size * 0.5,
              color: OraclyChrome.goldLight.withValues(alpha: 0.92),
            ),
          ),
        ),
      ),
    );
  }
}
