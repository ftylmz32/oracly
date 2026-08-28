/// Positive + negative quality actions under a finished reading.
library;

import 'package:flutter/material.dart';

import '../../../../core/quality/quality_feature.dart';
import 'reading_feedback_link.dart';
import 'reading_positive_link.dart';

class ReadingQualityActions extends StatelessWidget {
  const ReadingQualityActions({
    super.key,
    required this.feature,
    this.retry,
  });

  final QualityFeature feature;
  final Future<bool> Function()? retry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReadingPositiveLink(feature: feature),
        ReadingFeedbackLink(feature: feature, retry: retry),
      ],
    );
  }
}
