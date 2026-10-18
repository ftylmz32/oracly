/// Plate behind a bottom-aligned scene that can still scroll.
library;

import 'package:flutter/material.dart';

import 'encounter_plate.dart';

class EncounterStage extends StatelessWidget {
  const EncounterStage({super.key, required this.asset, required this.child});

  final String asset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        EncounterPlate(asset: asset),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(alignment: Alignment.bottomCenter, child: child),
              ),
            );
          },
        ),
      ],
    );
  }
}
