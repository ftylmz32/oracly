/// Validates proxy envelopes — invalid shape → typed failure, never crash.
library;

import 'dart:convert';

import '../ai_failure.dart';
import '../ai_outcome.dart';
import 'ai_error_mapper.dart';

abstract final class AiProxyResponseParser {
  AiProxyResponseParser._();

  static AiOutcome<Map<String, dynamic>> parse(String body) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final envelope = asStringMap(decoded);
    if (envelope == null) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final success = envelope['success'];
    if (success == false) {
      final error = asStringMap(envelope['error']);
      return AiOutcome.failure(AiErrorMapper.fromCode(error?['code'] as String?));
    }
    if (success != true) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final data = asStringMap(envelope['data']);
    if (data == null) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    return AiOutcome.success(data);
  }

  static Map<String, dynamic>? asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
