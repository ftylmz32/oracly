/// Home hero - cinematic oracle plate + real greeting logic.
library;

import 'package:flutter/material.dart';

import '../reference/home_reference_hero.dart';

class HomeMasterHero extends StatelessWidget {
  const HomeMasterHero({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) =>
      HomeReferenceHero(height: height ?? 156);
}
