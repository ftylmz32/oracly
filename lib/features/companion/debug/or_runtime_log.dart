/// OR runtime logs — lengths and flags only, never message text.
library;

import 'package:flutter/foundation.dart';

void logOrSession({
  required bool completed,
  required bool ready,
  String? errorType,
}) {
  if (!kDebugMode) return;
  // Failures only — successful bootstrap is silent.
  if (completed && ready && errorType == null) return;
  final extra = errorType == null ? '' : ' errorType=$errorType';
  debugPrint(
    'OR_SESSION: initializeCompleted=${completed ? 'yes' : 'no'} '
    'conversationReady=${ready ? 'yes' : 'no'}$extra',
  );
}

void logOrSubmit({
  required int textLength,
  required bool sessionReady,
  bool blocked = false,
}) {
  if (!kDebugMode) return;
  debugPrint(
    'OR_COMPOSER: submit textLength=$textLength '
    'sessionReady=${sessionReady ? 'yes' : 'no'} '
    'blocked=${blocked ? 'yes' : 'no'}',
  );
}
