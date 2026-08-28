/// Safe quality telemetry — categories only, never raw AI text.
library;

import 'package:flutter/foundation.dart';

import 'ai_output_quality_category.dart';

abstract final class AiOutputQualityLogger {
  AiOutputQualityLogger._();

  static void Function({
    required String operation,
    required String errorCategory,
  })? _severeSink;

  static void bindSevereSink(
    void Function({
      required String operation,
      required String errorCategory,
    }) sink,
  ) {
    _severeSink = sink;
  }

  static void logFailure({
    required String operationId,
    required AiOutputQualityCategory category,
    required int attempt,
  }) {
    if (kDebugMode) {
      debugPrint(
        'AI_QUALITY: op=$operationId category=${category.name} attempt=$attempt',
      );
    }
    if (!kReleaseMode || attempt < 2) return;
    _severeSink?.call(
      operation: operationId,
      errorCategory: category.name,
    );
  }
}
