/// Quality labels used by reading feedback — same wires as the quality loop.
library;

import '../../../core/quality/quality_feature.dart';
import '../../../core/quality/quality_issue.dart';

export '../../../core/quality/quality_feature.dart';
export '../../../core/quality/quality_issue.dart';

typedef ReadingFeedbackCategory = QualityIssue;
typedef ReadingFeedbackFeature = QualityFeature;
