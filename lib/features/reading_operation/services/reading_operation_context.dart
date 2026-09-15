import 'dart:async';

/// Carries the server operation identity through the existing Coffee/Palm
/// pipeline without changing its quality-facing interfaces.
abstract final class ReadingOperationContext {
  static const _key = #oraclyReadingOperationId;

  static String? get currentOperationId => Zone.current[_key] as String?;

  static Future<T> run<T>(String operationId, Future<T> Function() body) {
    return runZoned(body, zoneValues: {_key: operationId});
  }
}
