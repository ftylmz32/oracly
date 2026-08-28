/// Snapshot of which experiences feel weak or at ease.
library;

import 'quality_feature.dart';
import 'quality_issue.dart';

class QualityLoopReport {
  const QualityLoopReport({
    this.problematic,
    this.commonIssue,
    this.successful,
    this.empty = false,
  });

  final QualityFeature? problematic;
  final QualityIssue? commonIssue;
  final QualityFeature? successful;
  final bool empty;

  static const none = QualityLoopReport(empty: true);
}
