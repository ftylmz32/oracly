/// Full-bleed scene plate. Motion is a slow drift, frozen when reduced.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_reduced_motion.dart';

class EncounterPlate extends StatefulWidget {
  const EncounterPlate({super.key, required this.asset});

  final String asset;

  @override
  State<EncounterPlate> createState() => _EncounterPlateState();
}

class _EncounterPlateState extends State<EncounterPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 14000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyReducedMotion.stillLoop(context, _drift, reverse: true, rest: 0);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final scale = 1 + (_drift.value * 0.035);
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.asset(
        widget.asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF07060E)),
      ),
    );
  }
}
