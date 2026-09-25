/// Phase 7G — SHA-256 parity for committed Tarot golden masters.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'tarot_golden_harness.dart';

/// Keep in sync with docs/product/tarot/TAROT_PHASE7G_GOLDEN_MANIFEST.md
const tarotGoldenMasterNames = <String>[
  'table_intention',
  'table_spread_picker',
  'table_draw_ready_three',
  'table_draw_ready_five',
  'ritual_three_one_settled',
  'ritual_three_two_settled',
  'ritual_five_partial',
  'result_single_narrative',
  'result_three_narrative',
  'result_five_narrative',
  'result_long_narrative',
  'result_safety',
  'result_recovery',
  'history_list_mixed',
  'history_detail_narrative',
  'history_detail_crossroads',
  'compact_major_upright_52',
  'compact_major_reversed_52',
  'compact_minor_upright_52',
  'compact_major_upright_52_dpr2',
  'firewall_ritual_face_90',
  'firewall_ritual_face_132',
];

void main() {
  test('golden PNG inventory exists', () {
    for (final name in tarotGoldenMasterNames) {
      final path = '$tarotGoldenMasterDir/$name.png';
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('manifest SHA-256 parity when manifest present', () {
    final manifest =
        File('docs/product/tarot/TAROT_PHASE7G_GOLDEN_MANIFEST.md');
    expect(manifest.existsSync(), isTrue);
    final text = manifest.readAsStringSync();
    for (final name in tarotGoldenMasterNames) {
      final path = '$tarotGoldenMasterDir/$name.png';
      final hash = tarotGoldenSha256(path);
      expect(
        text.contains(hash),
        isTrue,
        reason: '$name.png hash $hash missing from manifest',
      );
    }
  });
}
