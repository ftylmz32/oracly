/// Phase 7A — SHA-256 inventory + negative control.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'yildizname_golden_harness.dart';

/// Keep in sync with YILDIZNAME_PHASE7A_VISUAL_FORENSIC_BASELINE.md
const yildiznameGoldenMasterNames = <String>[
  'hub_empty_390',
  'hub_with_birth_390',
  'legacy_result_390',
  'artifact_legacy_reopen_390',
  'artifact_narrative_reduced_current_390',
  'artifact_narrative_full_current_390',
  'firewall_result_chrome_control_390',
];

void main() {
  test('golden PNG inventory exists', () {
    for (final name in yildiznameGoldenMasterNames) {
      final path = '$yildiznameGoldenMasterDir/$name.png';
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('manifest SHA-256 parity when hashes present', () {
    final manifest = File(
      'docs/product/yildizname/YILDIZNAME_PHASE7A_VISUAL_FORENSIC_BASELINE.md',
    );
    expect(manifest.existsSync(), isTrue);
    final text = manifest.readAsStringSync();
    for (final name in yildiznameGoldenMasterNames) {
      final path = '$yildiznameGoldenMasterDir/$name.png';
      final hash = yildiznameGoldenSha256(path);
      expect(
        text.contains(hash),
        isTrue,
        reason: '$name.png hash $hash missing from baseline doc',
      );
    }
  });

  test('negative control — flipped byte fails hash match', () {
    final path =
        '$yildiznameGoldenMasterDir/firewall_result_chrome_control_390.png';
    expect(File(path).existsSync(), isTrue);
    final original = File(path).readAsBytesSync();
    expect(original.length, greaterThan(16));
    final flipped = Uint8List.fromList(original);
    flipped[8] = flipped[8] ^ 0xff;
    final bad = sha256.convert(flipped).toString();
    final good = yildiznameGoldenSha256(path);
    expect(bad, isNot(good));
    final manifest = File(
      'docs/product/yildizname/YILDIZNAME_PHASE7A_VISUAL_FORENSIC_BASELINE.md',
    ).readAsStringSync();
    expect(manifest.contains(bad), isFalse);
    expect(manifest.contains(good), isTrue);
  });
}
