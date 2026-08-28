/// SoulMate wait — dark portrait frame, slow light. No fake progress.
library;

import 'package:flutter/material.dart';

import '../../theme/oracly_quiet_motion.dart';
import '../oracly_chrome.dart';

class LoadingStageSoulMate extends StatefulWidget {
  const LoadingStageSoulMate({super.key, this.width = 168});

  final double width;

  @override
  State<LoadingStageSoulMate> createState() => _LoadingStageSoulMateState();
}

class _LoadingStageSoulMateState extends State<LoadingStageSoulMate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _reveal, reverse: true, rest: 0.42);
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 1.35;
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final t = _reveal.value;
        final light = 0.06 + t * 0.16;
        return SizedBox(
          width: w,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.heroRadius,
              color: const Color(0xFF07040F),
              border: Border.all(
                color: OraclyChrome.goldLight.withValues(alpha: 0.22 + t * 0.18),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: OraclyChrome.gold.withValues(alpha: light),
                  blurRadius: 36,
                ),
              ],
              gradient: RadialGradient(
                center: Alignment(0, -0.2 + t * 0.15),
                radius: 0.95,
                colors: [
                  OraclyChrome.cream.withValues(alpha: 0.04 + t * 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
