/// Maps HTTP / transport errors to typed [AiFailure] — never raw bodies.
library;

import '../ai_failure.dart';
import '../transport/ai_error_mapper.dart';

abstract final class OpenAiStatusMapper {
  OpenAiStatusMapper._();

  static AiFailure fromStatus(int statusCode) =>
      AiErrorMapper.fromStatus(statusCode);
}
