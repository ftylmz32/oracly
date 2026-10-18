/// Observatory plate cropped above the unlit floor.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/oracly_reduced_motion.dart';

class EncounterHallPlate extends StatefulWidget {
  const EncounterHallPlate({super.key});

  @override
  State<EncounterHallPlate> createState() => _EncounterHallPlateState();
}

class _EncounterHallPlateState extends State<EncounterHallPlate>
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
        return Transform.scale(scale: 1 + (_drift.value * 0.03), child: child);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crop = width * (900 / 720);
          return ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width,
                height: crop,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 900 / 1280,
                    child: Image.asset(
                      AppAssets.encounterHall,
                      width: width,
                      height: width * (1280 / 720),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF07060E)),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
