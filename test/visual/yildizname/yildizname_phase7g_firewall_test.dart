/// Phase 7G — production-path firewall (no forensic bypass APIs).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 7G sources never call forensic bypass APIs', () {
    final files = [
      'test/visual/yildizname/yildizname_phase7g_golden_master_test.dart',
      'test/visual/yildizname/yildizname_phase7g_golden_master_b_test.dart',
      'test/visual/yildizname/yildizname_phase7g_golden_master_c_test.dart',
      'test/visual/yildizname/yildizname_phase7g_capture.dart',
      'test/visual/yildizname/yildizname_phase7g_asserts.dart',
      'test/visual/yildizname/yildizname_phase7g_parity.dart',
      'test/visual/yildizname/yildizname_phase7g_fixtures.dart',
      'test/visual/yildizname/yildizname_phase7g_pump.dart',
      'test/visual/yildizname/yildizname_phase7g_names.dart',
      'test/visual/yildizname/yildizname_phase7g_golden_hash_test.dart',
      'test/visual/yildizname/yildizname_phase7g_manifest.dart',
    ];
    const forbidden = [
      '.unscoped',
      '.withoutRoleHierarchy',
      '.withForensicActionOrder',
      '.withForensicHideHistoricalStatus',
      'forensicFlatSections',
      'forensicLegacyActionOrder',
      'forensicHideHistoricalStatus',
      'withoutFactSnapshot',
    ];
    for (final path in files) {
      final text = File(path).readAsStringSync();
      for (final token in forbidden) {
        expect(
          text.contains(token),
          isFalse,
          reason: '$path contains forbidden $token',
        );
      }
    }
  });
}
