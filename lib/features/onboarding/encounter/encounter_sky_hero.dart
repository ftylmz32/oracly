/// Astronomical hero, faded into the fields beneath it.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import 'encounter_plate.dart';

class EncounterSkyHero extends StatelessWidget {
  const EncounterSkyHero({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: const Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment(0, -0.15),
              child: SizedBox(
                width: 720,
                height: 900,
                child: EncounterPlate(asset: AppAssets.encounterSky),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0007060E), Color(0xFF07060E)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
