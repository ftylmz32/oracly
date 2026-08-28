part of 'palm_image_metrics.dart';

PalmImageMetrics _fromCells({
  required double meanLuma,
  required double lumaStdDev,
  required double edgeEnergy,
  required List<int> cellN,
  required List<double> cellSum,
  required List<double> cellSq,
  required int width,
  required int height,
}) {
  const g = PalmImageMetrics.grid;
  final active = List<bool>.filled(g * g, false);
  var occ = 0;
  var center = 0;
  var centerN = 0;
  var border = 0;
  var borderN = 0;
  for (var y = 0; y < g; y++) {
    for (var x = 0; x < g; x++) {
      final i = y * g + x;
      final cn = cellN[i];
      final inCenter = x >= 5 && x < 11 && y >= 5 && y < 11;
      if (inCenter) {
        centerN++;
      } else {
        borderN++;
      }
      if (cn == 0) continue;
      final m = cellSum[i] / cn;
      final sd = math.sqrt(math.max(0, (cellSq[i] / cn) - m * m));
      final live = sd > 10 || (m - meanLuma).abs() > 28;
      if (!live) continue;
      active[i] = true;
      occ++;
      if (inCenter) {
        center++;
      } else {
        border++;
      }
    }
  }
  return PalmImageMetrics(
    meanLuma: meanLuma,
    lumaStdDev: lumaStdDev,
    edgeEnergy: edgeEnergy,
    occupancy: occ / (g * g),
    centerOccupancy: centerN == 0 ? 0 : center / centerN,
    borderOccupancy: borderN == 0 ? 0 : border / borderN,
    blobCount: _blobs(active),
    width: width,
    height: height,
  );
}

int _blobs(List<bool> active) {
  const g = PalmImageMetrics.grid;
  final seen = List<bool>.filled(g * g, false);
  var count = 0;
  for (var i = 0; i < active.length; i++) {
    if (!active[i] || seen[i]) continue;
    var size = 0;
    final stack = <int>[i];
    seen[i] = true;
    while (stack.isNotEmpty) {
      final cur = stack.removeLast();
      size++;
      final x = cur % g;
      final y = cur ~/ g;
      for (final d in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
        final nx = x + d.$1;
        final ny = y + d.$2;
        if (nx < 0 || ny < 0 || nx >= g || ny >= g) continue;
        final j = ny * g + nx;
        if (!active[j] || seen[j]) continue;
        seen[j] = true;
        stack.add(j);
      }
    }
    if (size >= 5) count++;
  }
  return count;
}
