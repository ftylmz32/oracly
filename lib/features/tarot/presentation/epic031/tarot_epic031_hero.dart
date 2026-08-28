/// EPIC-031 — Compact three-card Tarot hero.
library;

import 'package:flutter/material.dart';

import 'tarot_epic031_trio.dart';

class TarotEpic031Hero extends StatelessWidget {
  const TarotEpic031Hero({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return TarotEpic031Trio(height: height);
  }
}
