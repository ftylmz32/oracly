/// Structured proxy request — no giant UI string blobs.
library;

import 'ai_operation.dart';

class AiProxyRequest {
  const AiProxyRequest({
    required this.operation,
    required this.payload,
    this.model,
    this.idempotencyKey,
  });

  final AiOperation operation;
  final String? model;
  final Map<String, dynamic> payload;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() => {
        'operation': operation.wireName,
        if (model != null && model!.trim().isNotEmpty) 'model': model,
        'payload': payload,
      };
}
