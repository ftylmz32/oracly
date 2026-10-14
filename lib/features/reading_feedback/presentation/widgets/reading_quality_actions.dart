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
    this.contentRef,
    this.selectedContent,
  });

  final QualityFeature feature;
  final Future<bool> Function()? retry;
  final String? contentRef;
  final String? selectedContent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReadingPositiveLink(feature: feature),
        ReadingFeedbackLink(
          feature: feature,
          retry: retry,
          contentRef: contentRef,
          selectedContent: selectedContent,
        ),
      ],
    );
  }
}
