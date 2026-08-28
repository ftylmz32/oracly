/// Tiny presence lamp — idle / thinking / speaking / error. Never a mascot.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import 'companion_or_presence.dart';

class CompanionReferenceStatusPip extends StatelessWidget {
  const CompanionReferenceStatusPip({super.key, required this.presence});

  final CompanionOrPresence presence;

  @override
  Widget build(BuildContext context) {
    final color = switch (presence) {
      CompanionOrPresence.thinking => OraclyChrome.goldLight,
      CompanionOrPresence.speaking => OraclyChrome.gold,
      CompanionOrPresence.error || CompanionOrPresence.idle =>
        OraclyChrome.gold.withValues(alpha: 0.62),
    };
    if (presence == CompanionOrPresence.speaking &&
        !OraclyQuietMotion.still(context)) {
      return _SpeakingPip(color: color);
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: presence == CompanionOrPresence.idle
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 6,
                ),
              ],
      ),
    );
  }
}

class _SpeakingPip extends StatefulWidget {
  const _SpeakingPip({required this.color});

  final Color color;

  @override
  State<_SpeakingPip> createState() => _SpeakingPipState();
}

class _SpeakingPipState extends State<_SpeakingPip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _pulse, reverse: true, rest: 0.5);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value;
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35 + t * 0.35),
                blurRadius: 4 + t * 6,
              ),
            ],
          ),
        );
      },
    );
  }
}
