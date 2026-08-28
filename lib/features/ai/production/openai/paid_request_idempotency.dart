/// Idempotency key for paid proxy requests — binder wins over fingerprint.
library;

import '../../../gems/services/paid_ai_operation_binder.dart';
import '../ai_request_fingerprint.dart';

abstract final class PaidRequestIdempotency {
  PaidRequestIdempotency._();

  static String resolve(String fingerprint) {
    return PaidAiOperationBinder.idempotencyKey ??
        AiRequestFingerprint.idempotencyKey(fingerprint);
  }
}
