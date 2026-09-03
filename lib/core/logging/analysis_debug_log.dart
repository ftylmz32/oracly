/// Debug-only analysis failure — stage/kind/status only, never user content.
library;

import 'package:flutter/foundation.dart';

import '../../features/ai/production/ai_failure.dart';

void logAnalysisFailure({
  required String feature,
  required String stage,
  Object? error,
  String? kind,
  int? httpStatus,
  String? errorCode,
  String? endpoint,
}) {
  if (!kDebugMode) return;
  final parts = <String>[
    '[$feature]',
    'stage=$stage',
  ];
  if (kind != null) parts.add('kind=$kind');
  if (httpStatus != null) parts.add('httpStatus=$httpStatus');
  if (errorCode != null) parts.add('errorCode=$errorCode');
  if (endpoint != null) parts.add('endpoint=$endpoint');
  if (error is AiFailure) {
    parts.add('aiKind=${error.kind.name}');
  } else if (kind == null && errorCode == null) {
    parts.add('errorType=${error.runtimeType}');
  }
  debugPrint('${parts.join(' ')} failed');
}
