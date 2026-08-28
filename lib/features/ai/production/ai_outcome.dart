/// Success or typed failure — never a fake payload.
library;

import 'ai_failure.dart';

class AiOutcome<T> {
  const AiOutcome._({this.value, this.failure});

  final T? value;
  final AiFailure? failure;

  factory AiOutcome.success(T value) => AiOutcome._(value: value);

  factory AiOutcome.failure(AiFailure failure) =>
      AiOutcome._(failure: failure);

  bool get isSuccess => failure == null && value != null;

  bool get isFailure => failure != null;

  R when<R>({
    required R Function(T value) success,
    required R Function(AiFailure failure) error,
  }) {
    final fail = failure;
    if (fail != null) return error(fail);
    return success(value as T);
  }
}
