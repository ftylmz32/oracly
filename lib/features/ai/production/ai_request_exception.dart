/// Thrown across feature adapters so UI can show [AiFailure.userMessage].
library;

import 'ai_failure.dart';

class AiRequestException implements Exception {
  const AiRequestException(this.failure);

  final AiFailure failure;

  String get userMessage => failure.userMessage;

  @override
  String toString() => 'AiRequestException(${failure.kind})';
}
