/// Subtle earn pulse when gem balance rises — never casino.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/oracly_quiet_motion.dart';

class OraclyGemBalancePulse extends StatefulWidget {
  const OraclyGemBalancePulse({
    super.key,
    required this.balance,
    required this.child,
  });

  final int balance;
  final Widget child;

  @override
  State<OraclyGemBalancePulse> createState() => _OraclyGemBalancePulseState();
}

class _OraclyGemBalancePulseState extends State<OraclyGemBalancePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int? _lastBalance;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _lastBalance = widget.balance;
  }

  @override
  void didUpdateWidget(covariant OraclyGemBalancePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prev = _lastBalance;
    _lastBalance = widget.balance;
    if (prev != null && widget.balance > prev) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (OraclyQuietMotion.still(context)) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_pulse.value);
        final scale = 1 + (0.04 * (1 - t));
        return Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                if (_pulse.value > 0)
                  BoxShadow(
                    color: OraclyChrome.goldHighlight.withValues(
                      alpha: 0.22 * (1 - t),
                    ),
                    blurRadius: 10 * (1 - t),
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}