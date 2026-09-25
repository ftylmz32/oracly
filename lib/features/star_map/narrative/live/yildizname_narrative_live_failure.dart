/// Typed live-path failures — never canned StarMapCopy fallback.
library;

import '../result/yildizname_result_error.dart';

enum YildiznameLiveFailureKind {
  flagDisabled,
  provider,
  parse,
  quality,
  exhausted,
}

final class YildiznameLiveFailure implements Exception {
  YildiznameLiveFailure(
    this.kind, {
    this.message = '',
    this.cause,
    this.retryable = false,
  });

  final YildiznameLiveFailureKind kind;
  final String message;
  final Object? cause;
  final bool retryable;

  factory YildiznameLiveFailure.fromResult(YildiznameResultException e) {
    return YildiznameLiveFailure(
      YildiznameLiveFailureKind.quality,
      message: e.kind.name,
      cause: e,
      retryable: true,
    );
  }

  @override
  String toString() => 'YildiznameLiveFailure($kind: $message)';
}
