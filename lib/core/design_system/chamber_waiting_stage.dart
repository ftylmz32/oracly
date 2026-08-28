/// Ritual wait — radial gold bloom and quiet shimmer. Never a lone spinner.
library;

import 'package:flutter/material.dart';

import '../../shared/widgets/chamber_waiting_orb.dart';
import '../theme/oracly_quiet_motion.dart';
import '../theme/reading_typography.dart';
import 'chamber_hero_stage.dart';
import 'oracly_chrome.dart';
import 'oracly_soft_reveal.dart';

class ChamberWaitingStage extends StatefulWidget {
  const ChamberWaitingStage({super.key, required this.message});

  final String message;

  @override
  State<ChamberWaitingStage> createState() => _ChamberWaitingStageState();
}

class _ChamberWaitingStageState extends State<ChamberWaitingStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(
      context,
      _shimmer,
      reverse: true,
      rest: 0.45,
    );
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OraclySoftReveal(
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          final t = _shimmer.value;
          return ChamberHeroStage(
            warm: true,
            glow: 0.82 + t * 0.28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                child!,
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.opening(
                      color: OraclyChrome.cream.withValues(alpha: 0.90),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: const ChamberWaitingOrb(size: 96),
      ),
    );
  }
}
