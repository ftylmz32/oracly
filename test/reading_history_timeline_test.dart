import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/features/tarot/presentation/utils/reading_history_timeline.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

void main() {
  test('groupByDay clusters entries chronologically', () {
    final groups = ReadingHistoryTimeline.groupByDay(
      ReadingHistoryCatalogue.entries,
    );
    expect(groups, isNotEmpty);
    expect(
      groups.fold<int>(0, (sum, g) => sum + g.entries.length),
      ReadingHistoryCatalogue.entries.length,
    );
  });
}
