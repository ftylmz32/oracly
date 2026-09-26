/// Phase 7D.1 — forensic flatteners must not appear on production call sites.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ never calls withoutRoleHierarchy (forensic-only)', () {
    final hits = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      if (!text.contains('withoutRoleHierarchy')) continue;
      // Definition on the presentation type is allowed; call sites are not.
      final isDef = text.contains(
        'YildiznameResultPresentation withoutRoleHierarchy()',
      );
      if (isDef && !RegExp(r'\.withoutRoleHierarchy\s*\(').hasMatch(text)) {
        continue;
      }
      if (RegExp(r'\.withoutRoleHierarchy\s*\(').hasMatch(text)) {
        hits.add(f.path.replaceAll('\\', '/'));
      }
    }
    expect(hits, isEmpty, reason: 'production forensic bypass: $hits');
  });

  test('forensicFlatSections is only set true inside withoutRoleHierarchy', () {
    final hits = <String>[];
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = f.path.replaceAll('\\', '/');
      final text = f.readAsStringSync();
      if (!text.contains('forensicFlatSections: true')) continue;
      if (path.endsWith('yildizname_result_presentation.dart')) continue;
      hits.add(path);
    }
    expect(hits, isEmpty, reason: 'forensic true set outside presentation: $hits');
  });
}
