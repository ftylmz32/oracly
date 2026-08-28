/// Grounded deck breath — shadow and highlight, never levitation.
library;

import 'dart:math' show sin, pi;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'tarot_ambient_sync.dart';
import 'tarot_cinematic_motion.dart';

class TarotDeckIdle extends StatefulWidget {
  const TarotDeckIdle({super.key, required this.child});

  final Widget child;

  @override
  State<TarotDeckIdle> createState() => _TarotDeckIdleState();
}

class _TarotDeckIdleState extends State<TarotDeckIdle>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breath = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.deckIdle,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tarotSyncAmbient(context, _breath, reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    tarotSyncAmbient(context, _breath, reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final wave = sin(_breath.value * pi);
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28 + wave * 0.06),
                blurRadius: 16 + wave * 3,
                offset: Offset(0, 8 + wave * 1.2),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.04 + wave * 0.03),
                blurRadius: 10,
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
