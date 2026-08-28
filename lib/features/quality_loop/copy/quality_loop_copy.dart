/// Quality loop copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/quality/quality_feature.dart';
import '../../../core/quality/quality_issue.dart';
import '../../../core/quality/quality_loop_report.dart';
import '../../reading_feedback/copy/reading_feedback_copy.dart';

abstract final class QualityLoopCopy {
  QualityLoopCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get section => _t('quality.section');
  static String get empty => _t('quality.empty');
  static String get problem => _t('quality.problem');
  static String get issue => _t('quality.issue');
  static String get success => _t('quality.success');

  static String feature(QualityFeature value) =>
      _t('quality.feature.${value.wire}');

  static String issueLabel(QualityIssue value) =>
      ReadingFeedbackCopy.category(value);

  static String problemValue(QualityLoopReport report) {
    final feature = report.problematic;
    if (feature == null) return empty;
    return QualityLoopCopy.feature(feature);
  }

  static String successValue(QualityLoopReport report) {
    final feature = report.successful;
    if (feature == null) return empty;
    return QualityLoopCopy.feature(feature);
  }

  static String issueValue(QualityLoopReport report) {
    final issue = report.commonIssue;
    if (issue == null) return empty;
    return issueLabel(issue);
  }
}
