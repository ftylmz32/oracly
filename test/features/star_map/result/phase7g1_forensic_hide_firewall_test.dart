/// Production never sets forensicHideHistoricalStatus = true.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib never enables forensicHideHistoricalStatus', () {
    final root = Directory('lib/features/star_map');
    final hits = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.endsWith('yildizname_result_presentation.dart')) continue;
      if (path.endsWith('yildizname_result_presentation_forensic.dart')) {
        continue;
      }
      if (path.endsWith('yildizname_result_presentation_copy.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('forensicHideHistoricalStatus: true') ||
          text.contains('withForensicHideHistoricalStatus()')) {
        hits.add(path);
      }
    }
    expect(hits, isEmpty, reason: hits.join(', '));
  });
}
