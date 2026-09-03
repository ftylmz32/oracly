/// 3×2 discovery — cinematic tiles + Dream secondary doorway.
library;

import 'package:flutter/material.dart';

import '../reference/home_reference_module_grid.dart';
import '../reference/home_viewport_layout.dart';

class HomeMasterGrid extends StatelessWidget {
  const HomeMasterGrid({super.key, this.layout});

  final HomeViewportLayout? layout;

  @override
  Widget build(BuildContext context) =>
      HomeReferenceModuleGrid(layoutOverride: layout);
}
