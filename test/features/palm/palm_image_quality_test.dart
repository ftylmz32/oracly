/// Palm image quality heuristics — soft tips, rare hard fails only.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/services/palm_image_metrics.dart';
import 'package:oracly_new/features/palm/services/palm_image_validator.dart';

PalmImageMetrics _flat({required int fill, int speck = 0}) {
  final rgba = Uint8List(64 * 64 * 4);
  for (var i = 0; i < rgba.length; i += 4) {
    final bump = (i ~/ 4) % 11 == 0 ? speck : 0;
    rgba[i] = (fill + bump).clamp(0, 255);
    rgba[i + 1] = (fill - 4 + bump).clamp(0, 255);
    rgba[i + 2] = (fill - 8 + bump).clamp(0, 255);
    rgba[i + 3] = 255;
  }
  return PalmImageMetrics.fromRgba(rgba, 64, 64);
}

void main() {
  test('copy is practical and never medical', () {
    expect(PalmCopy.qualityBrighten, 'Avucunu biraz daha aydınlık çek.');
    expect(PalmCopy.qualityFrame, 'Parmaklar ve avuç içi birlikte görünsün.');
    expect(PalmCopy.qualityOneHand, 'Kadroda tek bir el olsun.');
    expect(PalmCopy.qualityCloser, 'Avucunu kadraja biraz daha yaklaştır.');
    expect(PalmCopy.qualityMissing.toLowerCase(), isNot(contains('tıbbi')));
    expect(PalmCopy.qualityMissing.toLowerCase(), isNot(contains('teşhis')));
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
    final metrics = PalmImageMetrics.fromRgba(rgba, 64, 64);
    expect(metrics.meanLuma, lessThan(PalmImageValidator.softDarkLuma));
    expect(metrics.meanLuma, greaterThan(PalmImageValidator.hardDarkLuma));
    final result = PalmImageValidator.assessMetrics(metrics);
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityBrighten);
  });

  test('near-black keeps photo with brighten guidance', () {
    final result = PalmImageValidator.assessMetrics(
      _flat(fill: 6, speck: 1),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityBrighten);
  });

  test('blank frame keeps photo with missing-palm guidance', () {
    final result = PalmImageValidator.assessMetrics(_flat(fill: 120));
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityMissing);
  });

  test('full textured frame passes without guidance', () {
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
    final result = PalmImageValidator.assessMetrics(
      PalmImageMetrics.fromRgba(rgba, 96, 96),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, isNull);
  });

  test('tiny subject stays acceptable with closer guidance', () {
    final rgba = Uint8List(96 * 96 * 4);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 96; x++) {
        final i = (y * 96 + x) * 4;
        final speck = x >= 34 && x < 62 && y >= 34 && y < 62;
        final v = speck ? ((x * 11 + y * 9) % 90) + 80 : 118;
        rgba[i] = v;
        rgba[i + 1] = v;
        rgba[i + 2] = v;
        rgba[i + 3] = 255;
      }
    }
    final result = PalmImageValidator.assessMetrics(
      PalmImageMetrics.fromRgba(rgba, 96, 96),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityCloser);
  });

  test('two distant textured regions stay acceptable with one-hand tip', () {
    final rgba = Uint8List(96 * 96 * 4);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 96; x++) {
        final i = (y * 96 + x) * 4;
        final left = x < 28 && y > 20 && y < 76;
        final right = x > 68 && y > 20 && y < 76;
        final live = left || right;
        final v = live ? ((x * 13 + y * 7) % 100) + 70 : 130;
        rgba[i] = v;
        rgba[i + 1] = v - 4;
        rgba[i + 2] = v - 8;
        rgba[i + 3] = 255;
      }
    }
    final result = PalmImageValidator.assessMetrics(
      PalmImageMetrics.fromRgba(rgba, 96, 96),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityOneHand);
  });

  test('smooth low-edge frame stays acceptable with blur guidance', () {
    final rgba = Uint8List(96 * 96 * 4);
    for (var y = 0; y < 96; y++) {
      for (var x = 0; x < 96; x++) {
        final i = (y * 96 + x) * 4;
        final dx = x - 48;
        final dy = y - 48;
        final inside = dx * dx + dy * dy < 40 * 40;
        final v = inside ? 70 + ((x + y) % 36) : 200;
        rgba[i] = v;
        rgba[i + 1] = v;
        rgba[i + 2] = v;
        rgba[i + 3] = 255;
      }
    }
    final metrics = PalmImageMetrics.fromRgba(rgba, 96, 96);
    expect(metrics.occupancy, greaterThan(PalmImageValidator.softTinyOcc));
    expect(metrics.edgeEnergy, lessThan(PalmImageValidator.softBlurEdge));
    final result = PalmImageValidator.assessMetrics(metrics);
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityBlur);
  });

  test('busy border and empty center stays acceptable with frame tip', () {
    final rgba = Uint8List(90 * 90 * 4);
    for (var y = 0; y < 90; y++) {
      for (var x = 0; x < 90; x++) {
        final i = (y * 90 + x) * 4;
        final center = x >= 22 && x < 68 && y >= 22 && y < 68;
        final v = center ? 90 : ((x * 9 + y * 5) % 140) + 50;
        rgba[i] = v;
        rgba[i + 1] = v;
        rgba[i + 2] = v;
        rgba[i + 3] = 255;
      }
    }
    final result = PalmImageValidator.assessMetrics(
      PalmImageMetrics.fromRgba(rgba, 90, 90),
    );
    expect(result.ok, isTrue);
    expect(result.guidance, PalmCopy.qualityFrame);
  });
}
