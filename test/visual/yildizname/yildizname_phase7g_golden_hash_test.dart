/// Phase 7G — SHA-256 inventory with exact filename→hash binding.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yildizname_golden_harness.dart';
import 'yildizname_phase7g_manifest.dart';
import 'yildizname_phase7g_names.dart';

void main() {
  final manifestFile = File(
    'docs/product/yildizname/YILDIZNAME_PHASE7G_GOLDEN_MANIFEST.md',
  );

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

  test('C/D exact filename→SHA-256 binding for all 17 masters', () {
    expect(manifestFile.existsSync(), isTrue);
    final map = yildiznamePhase7gParseManifestHashes(
      manifestFile.readAsStringSync(),
    );
    expect(map.length, 17);
    expect(
      map.keys.toSet(),
      yildiznamePhase7gGoldenMasterNames.map((n) => '$n.png').toSet(),
    );
    for (final name in yildiznamePhase7gGoldenMasterNames) {
      final file = '$name.png';
      final actual =
          yildiznameGoldenSha256('$yildiznamePhase7gGoldenDir/$file');
      expect(
        map[file],
        actual,
        reason: '$file manifest hash must equal file bytes',
      );
      expect(
        RegExp(r'^[0-9a-f]{64}$').hasMatch(actual),
        isTrue,
        reason: '$file hash not full 64-hex',
      );
    }
  });

  test('D manifest declares correct PNG/hash count', () {
    final text = manifestFile.readAsStringSync();
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
    final map = yildiznamePhase7gParseManifestHashes(
      manifestFile.readAsStringSync(),
    );
    expect(map.values.contains(bad), isFalse);
    expect(map.values.contains(good), isTrue);
  });

  test('swapped filename hashes rejected by exact binding', () {
    final map = yildiznamePhase7gParseManifestHashes(
      manifestFile.readAsStringSync(),
    );
    final a = 'final_hub_empty_390.png';
    final b = 'final_hub_with_birth_390.png';
    final swapped = Map<String, String>.from(map);
    final tmp = swapped[a]!;
    swapped[a] = swapped[b]!;
    swapped[b] = tmp;
    expect(swapped[a], isNot(map[a]));
    final actualA =
        yildiznameGoldenSha256('$yildiznamePhase7gGoldenDir/$a');
    expect(
      swapped[a] == actualA,
      isFalse,
      reason: 'swapped hub empty hash must not equal actual file',
    );
  });
}
