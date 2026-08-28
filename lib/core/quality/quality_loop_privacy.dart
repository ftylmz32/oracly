/// Rejects private payloads — never used to train a model.
library;

import 'quality_signal_event.dart';

abstract final class QualityLoopPrivacy {
  QualityLoopPrivacy._();

  static const storesRawContent = false;
  static const trainsFromUserContent = false;

  static const forbiddenKeys = {
    'text',
    'message',
    'content',
    'quote',
    'narrative',
    'prompt',
    'response',
    'body',
    'question',
    'image',
  };

  static bool isSafe(Map<String, dynamic> json) {
    if (json.keys.any(forbiddenKeys.contains)) return false;
    return json.keys.every(QualitySignalEvent.allowedKeys.contains);
  }
}
