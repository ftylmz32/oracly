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

/// Stage markers only — never message content or tokens.
void logOrPersist({
  required String stage,
  required bool ok,
  String? errorType,
  bool? fromAi,
  bool? priorUserSaved,
}) {
  if (!kDebugMode) return;
  final bits = <String>[
    'stage=$stage',
    'ok=${ok ? 'yes' : 'no'}',
    if (fromAi != null) 'fromAi=${fromAi ? 'yes' : 'no'}',
    if (priorUserSaved != null)
      'priorUserSaved=${priorUserSaved ? 'yes' : 'no'}',
    if (errorType != null) 'errorType=$errorType',
  ];
  debugPrint('OR_PERSIST: ${bits.join(' ')}');
}

void logOrCorruptRow({required String reason}) {
  if (!kDebugMode) return;
  debugPrint('OR_HISTORY: quarantine reason=$reason');
}
