/// Phase 7E.1 — production must not open results with empty actions.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _entries = [
  'lib/features/star_map/presentation/reference/star_map_result_open.dart',
  'lib/features/star_map/presentation/reference/star_map_artifact_reopen_screen.dart',
  'lib/features/star_map/artifacts/yildizname_artifact_presentation.dart',
  'lib/features/star_map/result/yildizname_result_presentation_build.dart',
];

void main() {
  test('canonical result entry points build actions via the builder', () {
    for (final path in _entries) {
      final code = File(path).readAsStringSync();
      expect(
        code.contains('YildiznameResultActionsBuilder.build'),
        isTrue,
        reason: path,
      );
      expect(
        code.contains('YildiznameResultActions.empty'),
        isFalse,
        reason: '$path must not force empty actions',
      );
    }
  });

  test('lib/ star_map never assigns ResultActions.empty on purpose', () {
    final hits = <String>[];
    for (final f in Directory('lib/features/star_map')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = f.path.replaceAll('\\', '/');
      final text = f.readAsStringSync();
      if (!text.contains('YildiznameResultActions.empty')) continue;
      // Allowed: definition + constructor null-coalesce fallback only.
      if (path.endsWith('yildizname_result_actions.dart')) continue;
      if (path.endsWith('yildizname_result_presentation.dart') &&
          text.contains('actions ?? YildiznameResultActions.empty')) {
        continue;
      }
      hits.add(path);
    }
    expect(hits, isEmpty, reason: 'production empty-action callers: $hits');
  });
}
