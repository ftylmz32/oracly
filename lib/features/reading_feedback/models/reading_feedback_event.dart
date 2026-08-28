/// Quality metadata only — no reading text, no questions, no quotes.
library;

import 'reading_feedback_category.dart';

class ReadingFeedbackEvent {
  const ReadingFeedbackEvent({
    required this.feature,
    required this.category,
    required this.ok,
    required this.at,
  });

  final ReadingFeedbackFeature feature;
  final ReadingFeedbackCategory category;
  final bool ok;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'feature': feature.wire,
        'category': category.wire,
        'ok': ok,
        'at': at.toIso8601String(),
      };

  factory ReadingFeedbackEvent.fromJson(Map<String, dynamic> json) {
    return ReadingFeedbackEvent(
      feature: QualityFeature.fromWire('${json['feature']}') ??
          QualityFeature.tarot,
      category: QualityIssue.fromWire('${json['category']}') ??
          QualityIssue.generic,
      ok: json['ok'] == true,
      at: DateTime.tryParse('${json['at']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static const allowedKeys = {'feature', 'category', 'ok', 'at'};
}
