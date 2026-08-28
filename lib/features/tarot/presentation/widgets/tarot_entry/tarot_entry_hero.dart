/// Entry hero — physical deck on a quiet velvet bed.
library;

import 'package:flutter/material.dart';

import '../../../../../core/widgets/oracly_signature_motifs.dart';
import '../../../motion/tarot_deck_idle.dart';
import '../../../motion/tarot_entry_reveal.dart';
import '../../../motion/tarot_foil_glide.dart';
import '../deck/physical_deck_stack.dart';
import '../deck/tarot_deck_table_atmosphere.dart';

class TarotEntryHero extends StatelessWidget {
  const TarotEntryHero({super.key, this.height = 220});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment(0, 0.48),
            child: TarotDeckTableAtmosphere(
              width: 248,
              height: 92,
              candleBias: Alignment(0.38, -0.52),
            ),
          ),
          Positioned(
            top: 8,
            child: SizedBox(
              width: 72,
              height: 14,
              child: CustomPaint(painter: OraclySignatureDividerPainter()),
            ),
          ),
          TarotDeckIdle(
            child: PhysicalDeckStack(
              width: 108,
              height: 176,
              layers: 7,
            ),
          ),
          Positioned.fill(
            child: TarotFoilGlide(progress: tarotEntryGlintOf(context)),
          ),
        ],
      ),
    );
  }
}
