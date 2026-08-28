/// Coffee image quality heuristics — soft tips, rare hard fails only.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_metrics.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_validator.dart';

CoffeeImageMetrics _metrics({
  required int fill,
  int speck = 0,
  int width = 64,
  int height = 64,
}) {
  final rgba = Uint8List(width * height * 4);
  for (var i = 0; i < rgba.length; i += 4) {
    final bump = (i ~/ 4) % 11 == 0 ? speck : 0;
    rgba[i] = (fill + bump).clamp(0, 255);
    rgba[i + 1] = (fill - 4 + bump).clamp(0, 255);
    rgba[i + 2] = (fill - 8 + bump).clamp(0, 255);
    rgba[i + 3] = 255;
  }
  return CoffeeImageMetrics.fromRgba(rgba, width, height);
}

void main() {
  test('copy offers practical Turkish guidance', () {
    expect(CoffeeCopy.qualityBrighten, 'Fincanın içini biraz daha aydınlık çek.');
    expect(
      CoffeeCopy.qualityFrame,
      'Fincanın içi kadrajda, ortada ve net görünsün.',
    );
  });

  test('soft dark stays acceptable with brighten guidance', () {
    final rgba = Uint8List(64 * 64 * 4);
    for (var y = 0; y < 64; y++) {
      for (var x = 0; x < 64; x++) {
        final i = (y * 64 + x) * 4;
        final v = 30 + ((x + y) % 20);
        rgba[i] = v;
        rgba[i + 1] = v - 2;
        rgba[i + 2] = v - 4;
        rgba[i + 3] = 255;
      }
    }
    final metrics = CoffeeImageMetrics.fromRgba(rgba, 64, 64);
    expect(metrics.meanLuma, lessThan(CoffeeImageValidator.softDarkLuma));
    expect(metrics.meanLuma, greaterThan(CoffeeImageValidator.hardDarkLuma));
    expect(metrics.lumaStdDev, greaterThan(CoffeeImageValidator.hardFlatStd));
    final result = CoffeeImageValidator.assessMetrics(metrics);
    expect(result.ok, isTrue);
    expect(result.guidance, CoffeeCopy.qualityBrighten);
  });

  test('near-black keeps photo with brighten guidance', () {
    final result = CoffeeImageValidator.assessMetrics(
      _metrics(fill: 6, speck: 1),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, CoffeeCopy.qualityBrighten);
  });

  test('flat frame keeps photo with frame guidance', () {
    final result = CoffeeImageValidator.assessMetrics(
      _metrics(fill: 120, speck: 0),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, CoffeeCopy.qualityFrame);
  });

  test('textured cup-like frame passes without guidance', () {
    final rgba = Uint8List(96 * 96 * 4);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 96; x++) {
        final i = (y * 96 + x) * 4;
        final v = ((x * 7 + y * 3) % 110) + 70;
        rgba[i] = v;
        rgba[i + 1] = v - 8;
        rgba[i + 2] = v - 16;
        rgba[i + 3] = 255;
      }
    }
    final result = CoffeeImageValidator.assessMetrics(
      CoffeeImageMetrics.fromRgba(rgba, 96, 96),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, isNull);
  });

  test('soft framing tip when center is empty and border is busy', () {
    final rgba = Uint8List(90 * 90 * 4);
    for (var y = 0; y < 90; y++) {
      for (var x = 0; x < 90; x++) {
        final i = (y * 90 + x) * 4;
        final center = x >= 30 && x < 60 && y >= 30 && y < 60;
        final v = center ? 40 : ((x * 9 + y * 5) % 140) + 50;
        rgba[i] = v;
        rgba[i + 1] = v;
        rgba[i + 2] = v;
        rgba[i + 3] = 255;
      }
    }
    final result = CoffeeImageValidator.assessMetrics(
      CoffeeImageMetrics.fromRgba(rgba, 90, 90),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, CoffeeCopy.qualityFrame);
  });
}
