/// Reading feedback copy.
library;

import '../../../core/l10n/l10n.dart';
import '../models/reading_feedback_category.dart';

abstract final class ReadingFeedbackCopy {
  ReadingFeedbackCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get action => _t('feedback.action');
  static String get title => _t('feedback.title');
  static String get hint => _t('feedback.hint');
  static String get retry => _t('feedback.retry');
  static String get retryNote => _t('feedback.retry.note');
  static String get send => _t('feedback.send');
  static String get thanks => _t('feedback.thanks');
  static String get retrying => _t('feedback.retrying');
  static String get retryOk => _t('feedback.retry.ok');
  static String get retryFail => _t('feedback.retry.fail');

  static String category(QualityIssue value) => switch (value) {
        QualityIssue.missed => _t('feedback.cat.missed'),
        QualityIssue.generic => _t('feedback.cat.generic'),
        QualityIssue.unanswered => _t('feedback.cat.unanswered'),
        QualityIssue.repetitive => _t('feedback.cat.repetitive'),
        QualityIssue.inappropriate => _t('feedback.cat.inappropriate'),
      };

  static String get positive => _t('feedback.positive');
  static String get positiveThanks => _t('feedback.positive.thanks');
}
