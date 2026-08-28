/// Shared constellation model for symbolic sign star maps.
library;

import 'package:flutter/material.dart';

typedef AstrologyConstellationEdge = (int, int);

final class AstrologySignConstellation {
  const AstrologySignConstellation({
    required this.points,
    required this.edges,
  });

  final List<Offset> points;
  final List<AstrologyConstellationEdge> edges;
}
