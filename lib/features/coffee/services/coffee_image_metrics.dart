/// Local pixel heuristics for cup photos — not computer vision or cup ML.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

class CoffeeImageMetrics {
  const CoffeeImageMetrics({
    required this.meanLuma,
    required this.lumaStdDev,
    required this.edgeEnergy,
    required this.centerVariance,
    required this.borderVariance,
    required this.width,
    required this.height,
  });

  final double meanLuma;
  final double lumaStdDev;
  final double edgeEnergy;
  final double centerVariance;
  final double borderVariance;
  final int width;
  final int height;

  static Future<CoffeeImageMetrics?> fromImage(Image image) async {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    if (data == null) return null;
    return fromRgba(
      data.buffer.asUint8List(),
      image.width,
      image.height,
    );
  }

  static CoffeeImageMetrics fromRgba(Uint8List rgba, int width, int height) {
    final step = math.max(1, math.min(width, height) ~/ 64);
    var sum = 0.0;
    var sumSq = 0.0;
    var edge = 0.0;
    var edgeN = 0;
    var n = 0;
    var centerSum = 0.0;
    var centerSumSq = 0.0;
    var centerN = 0;
    var borderSum = 0.0;
    var borderSumSq = 0.0;
    var borderN = 0;
    final x0 = width ~/ 3;
    final x1 = (width * 2) ~/ 3;
    final y0 = height ~/ 3;
    final y1 = (height * 2) ~/ 3;

    for (var y = 0; y < height; y += step) {
      for (var x = 0; x < width; x += step) {
        final i = (y * width + x) * 4;
        final luma = 0.299 * rgba[i] + 0.587 * rgba[i + 1] + 0.114 * rgba[i + 2];
        sum += luma;
        sumSq += luma * luma;
        n++;
        final inCenter = x >= x0 && x < x1 && y >= y0 && y < y1;
        if (inCenter) {
          centerSum += luma;
          centerSumSq += luma * luma;
          centerN++;
        } else {
          borderSum += luma;
          borderSumSq += luma * luma;
          borderN++;
        }
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
    return CoffeeImageMetrics(
      meanLuma: mean,
      lumaStdDev: math.sqrt(math.max(0, variance)),
      edgeEnergy: edgeN == 0 ? 0.0 : edge / edgeN,
      centerVariance: _var(centerSum, centerSumSq, centerN),
      borderVariance: _var(borderSum, borderSumSq, borderN),
      width: width,
      height: height,
    );
  }

  static double _var(double sum, double sumSq, int n) {
    if (n == 0) return 0;
    final mean = sum / n;
    return math.max(0, (sumSq / n) - mean * mean);
  }
}
