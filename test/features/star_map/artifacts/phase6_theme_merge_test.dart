/// J — Theme merge prefers history; max 3; case-insensitive dedupe.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_memory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_theme_merge.dart';

void main() {
  test('J merge X,Y history + Y,Z discovery → X,Y,Z', () {
    final history = [
      YildiznameRecurringTheme(
        themeKey: 'yth_xxxxxxxxxxxxxxxx',
        label: 'X',
        supportCount: 3,
        sourceArtifactIds: const ['a', 'b'],
        latestOccurredAt: DateTime.utc(2026, 1, 3),
      ),
      YildiznameRecurringTheme(
        themeKey: 'yth_yyyyyyyyyyyyyyyy',
        label: 'Y',
        supportCount: 2,
        sourceArtifactIds: const ['a', 'c'],
        latestOccurredAt: DateTime.utc(2026, 1, 2),
      ),
    ];
    final merged = YildiznameThemeMerge.mergeLabels(
      artifactThemes: history,
      personalDiscoveryLabels: const ['y', 'Z', 'W'],
    );
    expect(merged, ['X', 'Y', 'Z']);
    expect(merged, isNot(contains('W')));
  });
}
