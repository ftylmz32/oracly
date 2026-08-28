/// Debug-only analysis failure — category/kind only, never user content.
library;

import 'package:flutter/foundation.dart';

void logAnalysisFailure({
  required String feature,
  required String stage,
  Object? error,
  String? kind,
}) {
  if (!kDebugMode) return;
  final detail = kind != null
      ? 'kind=$kind'
      : 'errorType=${error.runtimeType}';
  debugPrint('[$feature] failed stage=$stage $detail');
}
