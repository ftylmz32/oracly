/// Local pixel heuristics for palm photos — not hand detection or vision.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

part 'palm_image_metrics_grid.dart';

class PalmImageMetrics {
  const PalmImageMetrics({
    required this.meanLuma,
    required this.lumaStdDev,
    required this.edgeEnergy,
    required this.occupancy,
    required this.centerOccupancy,
    required this.borderOccupancy,
    required this.blobCount,
    required this.width,
    required this.height,
  });

  final double meanLuma;
  final double lumaStdDev;
  final double edgeEnergy;
  final double occupancy;
  final double centerOccupancy;
  final double borderOccupancy;
  final int blobCount;
  final int width;
  final int height;

  static const grid = 16;

  static Future<PalmImageMetrics?> fromImage(Image image) async {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (data == null) return null;
    return fromRgba(data.buffer.asUint8List(), image.width, image.height);
  }

  static PalmImageMetrics fromRgba(Uint8List rgba, int width, int height) {
    final step = math.max(1, math.min(width, height) ~/ 64);
    var sum = 0.0;
    var sumSq = 0.0;
    var edge = 0.0;
    var edgeN = 0;
    var n = 0;
    final cellN = List<int>.filled(grid * grid, 0);
    final cellSum = List<double>.filled(grid * grid, 0);
    final cellSq = List<double>.filled(grid * grid, 0);
    for (var y = 0; y < height; y += step) {
      for (var x = 0; x < width; x += step) {
        final i = (y * width + x) * 4;
        final luma = 0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];
        sum += luma;
        sumSq += luma * luma;
        n++;
        final gx = math.min(grid - 1, (x * grid) ~/ width);
        final gy = math.min(grid - 1, (y * grid) ~/ height);
        final c = gy * grid + gx;
        cellN[c]++;
        cellSum[c] += luma;
        cellSq[c] += luma * luma;
        if (x + step < width) {
          final j = (y * width + x + step) * 4;
          final right =
              0.299 * rgba[j] + 0.587 * rgba[j + 1] + 0.114 * rgba[j + 2];
          edge += (luma - right).abs();
          edgeN++;
        }
        if (y + step < height) {
          final j = ((y + step) * width + x) * 4;
          final down =
              0.299 * rgba[j] + 0.587 * rgba[j + 1] + 0.114 * rgba[j + 2];
          edge += (luma - down).abs();
          edgeN++;
        }
      }
    }
    final mean = n == 0 ? 0.0 : sum / n;
    final variance = n == 0 ? 0.0 : (sumSq / n) - mean * mean;
    return _fromCells(
      meanLuma: mean,
      lumaStdDev: math.sqrt(math.max(0, variance)),
      edgeEnergy: edgeN == 0 ? 0.0 : edge / edgeN,
      cellN: cellN,
      cellSum: cellSum,
      cellSq: cellSq,
      width: width,
      height: height,
    );
  }
}
