/// Minimal revisit context — topic and spread, never surveillance detail.
library;

import '../../../core/domain/models/reading.dart';

class TarotRevisitContext {
  const TarotRevisitContext({
    required this.reading,
    required this.topicLabel,
    required this.spreadLabel,
    this.questionHint,
  });

  final ReadingModel reading;
  final String? topicLabel;
  final String spreadLabel;
  final String? questionHint;
}
