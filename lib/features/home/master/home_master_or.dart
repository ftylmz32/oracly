/// OR flagship - cinematic plate, canonical /chat only.
library;

import 'package:flutter/material.dart';

import '../reference/home_reference_or_guide_section.dart';

class HomeMasterOr extends StatelessWidget {
  const HomeMasterOr({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) =>
      HomeReferenceOrGuideSection(height: height);
}
