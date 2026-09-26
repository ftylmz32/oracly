/// Phase 7G — SHA-256 inventory + negative control (test-only).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yildizname_golden_harness.dart';
import 'yildizname_phase7g_names.dart';

void main() {
  test('A every declared Phase 7G PNG exists', () {
    for (final name in yildiznamePhase7gGoldenMasterNames) {
      final path = '$yildiznamePhase7gGoldenDir/$name.png';
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('B directory contains exactly the declared inventory', () {
    final dir = Directory(yildiznamePhase7gGoldenDir);
    expect(dir.existsSync(), isTrue);
    final pngs = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
        .toList()
      ..sort();
    final expected = [...yildiznamePhase7gGoldenMasterNames]..sort();
    expect(pngs, expected);
  });

  test('C each PNG SHA-256 exists in Phase 7G manifest', () {
    final manifest = File(
      'docs/product/yildizname/YILDIZNAME_PHASE7G_GOLDEN_MANIFEST.md',
    );
    expect(manifest.existsSync(), isTrue);
    final text = manifest.readAsStringSync();
    for (final name in yildiznamePhase7gGoldenMasterNames) {
      final path = '$yildiznamePhase7gGoldenDir/$name.png';
      final hash = yildiznameGoldenSha256(path);
      expect(
        text.contains(hash),
        isTrue,
        reason: '$name.png hash $hash missing from manifest',
      );
    }
  });

  test('D manifest declares correct PNG/hash count', () {
    final text = File(
      'docs/product/yildizname/YILDIZNAME_PHASE7G_GOLDEN_MANIFEST.md',
    ).readAsStringSync();
    expect(text.contains('**PNG count:** 17'), isTrue);
    expect(text.contains('**Hash count:** 17'), isTrue);
    expect(yildiznamePhase7gGoldenMasterNames, hasLength(17));
  });

  test('E no duplicate master names', () {
    expect(
      yildiznamePhase7gGoldenMasterNames.toSet(),
      hasLength(yildiznamePhase7gGoldenMasterNames.length),
    );
  });

  test('negative control — flipped byte fails hash match', () {
    final path =
        '$yildiznamePhase7gGoldenDir/final_narrative_full_rich_390.png';
    expect(File(path).existsSync(), isTrue);
    final original = File(path).readAsBytesSync();
    expect(original.length, greaterThan(16));
    final flipped = Uint8List.fromList(original);
    flipped[8] = flipped[8] ^ 0xff;
    final bad = sha256.convert(flipped).toString();
    final good = yildiznameGoldenSha256(path);
    expect(bad, isNot(good));
    final manifest = File(
      'docs/product/yildizname/YILDIZNAME_PHASE7G_GOLDEN_MANIFEST.md',
    ).readAsStringSync();
    expect(manifest.contains(bad), isFalse);
    expect(manifest.contains(good), isTrue);
  });
}
