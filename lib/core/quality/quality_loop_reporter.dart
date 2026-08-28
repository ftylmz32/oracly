/// Identifies weak and strong experiences from metadata only.
library;

import 'quality_feature.dart';
import 'quality_issue.dart';
import 'quality_loop_report.dart';
import 'quality_signal_event.dart';
import 'quality_signal_kind.dart';

abstract final class QualityLoopReporter {
  QualityLoopReporter._();

  static QualityLoopReport from(List<QualitySignalEvent> events) {
    if (events.isEmpty) return QualityLoopReport.none;
    final stats = <QualityFeature, _Stat>{
      for (final feature in QualityFeature.values) feature: _Stat(),
    };
    final issues = <QualityIssue, int>{};
    for (final event in events) {
      final row = stats[event.feature]!;
      switch (event.kind) {
        case QualitySignalKind.started:
          row.started++;
        case QualitySignalKind.completed:
          row.completed++;
        case QualitySignalKind.abandoned:
          row.abandoned++;
        case QualitySignalKind.positive:
          row.positive++;
        case QualitySignalKind.negative:
          row.negative++;
          final issue = event.issue;
          if (issue != null) {
            issues[issue] = (issues[issue] ?? 0) + 1;
          }
        case QualitySignalKind.retry:
          row.retry++;
      }
    }
    QualityFeature? problematic;
    var problemScore = -1;
    QualityFeature? successful;
    var successScore = -1;
    for (final entry in stats.entries) {
      if (entry.value.isEmpty) continue;
      final problem = entry.value.negative * 3 +
          entry.value.abandoned * 2 +
          entry.value.retry;
      if (problem > problemScore) {
        problemScore = problem;
        problematic = entry.key;
      }
      final success =
          entry.value.positive * 2 + entry.value.completed - entry.value.negative * 2;
      if (success > successScore) {
        successScore = success;
        successful = entry.key;
      }
    }
    QualityIssue? common;
    var commonCount = 0;
    for (final entry in issues.entries) {
      if (entry.value > commonCount) {
        commonCount = entry.value;
        common = entry.key;
      }
    }
    if (problematic == null && successful == null && common == null) {
      return QualityLoopReport.none;
    }
    return QualityLoopReport(
      problematic: problemScore > 0 ? problematic : null,
      commonIssue: common,
      successful: successScore > 0 ? successful : null,
    );
  }
}

class _Stat {
  int started = 0;
  int completed = 0;
  int abandoned = 0;
  int positive = 0;
  int negative = 0;
  int retry = 0;

  bool get isEmpty =>
      started == 0 &&
      completed == 0 &&
      abandoned == 0 &&
      positive == 0 &&
      negative == 0 &&
      retry == 0;
}
