/// Safe outcome of one store catalogue check — technical diagnostics only.
///
/// Holds product identifiers, store status codes and exception TYPES. Never
/// receipts, transaction data, verification payloads, tokens or identity.
library;

import 'package:flutter/foundation.dart';

@immutable
class StoreCatalogSnapshot {
  StoreCatalogSnapshot({
    required this.at,
    required this.storeAvailable,
    this.availabilityTimedOut = false,
    this.availabilityExceptionType,
    Iterable<String> requestedIds = const [],
    Iterable<String> returnedIds = const [],
    Iterable<String> notFoundIds = const [],
    this.errorCode,
    String? errorMessage,
    this.queryTimedOut = false,
    this.queryExceptionType,
    this.attempt = 0,
  }) : requestedIds = _sorted(requestedIds),
       returnedIds = _sorted(returnedIds),
       notFoundIds = _sorted(notFoundIds),
       errorMessage = capMessage(errorMessage);

  static const maxMessageLength = 160;

  /// UTC capture time.
  final DateTime at;
  final bool storeAvailable;
  final bool availabilityTimedOut;
  final String? availabilityExceptionType;
  final List<String> requestedIds;

  /// Every product id the store returned, including unrequested ones.
  final List<String> returnedIds;

  /// Ids the store explicitly reported as not found. Empty when the store
  /// gave no answer (timeout / exception) — never synthesized.
  final List<String> notFoundIds;
  final String? errorCode;

  /// Store error message, whitespace-collapsed and length-capped.
  final String? errorMessage;
  final bool queryTimedOut;
  final String? queryExceptionType;

  /// Query attempt within one prepare (0 = no query was made).
  final int attempt;

  static List<String> _sorted(Iterable<String> ids) =>
      List.unmodifiable(ids.map((id) => id.trim()).toList()..sort());

  static String? capMessage(String? raw) {
    if (raw == null) return null;
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return null;
    if (collapsed.length <= maxMessageLength) return collapsed;
    return '${collapsed.substring(0, maxMessageLength)}…';
  }

  /// Type name only — exception messages may carry arbitrary payloads.
  static String exceptionType(Object error) => error.runtimeType.toString();
}

/// Read-only access to the latest catalogue snapshot, implemented by the
/// real store port only — closed/test ports need not know about it.
abstract interface class StoreCatalogDiagnosticsSource {
  StoreCatalogSnapshot? get catalogSnapshot;
}
