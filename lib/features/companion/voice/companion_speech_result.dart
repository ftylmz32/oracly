/// One STT update - text always; confidence only when the platform provides it.
library;

class CompanionSpeechResult {
  const CompanionSpeechResult({
    required this.text,
    required this.isFinal,
    this.confidence,
  });

  final String text;
  final bool isFinal;

  /// 0-1 when rated. Null when the platform has no confidence signal.
  final double? confidence;

  bool get hasConfidence => confidence != null && confidence! > 0;

  /// Soft threshold - only used when [hasConfidence] is true.
  bool get isLowConfidence =>
      hasConfidence && confidence! < CompanionSpeechResult.reviewThreshold;

  static const double reviewThreshold = 0.6;
}
