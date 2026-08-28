/// AI transport — proxy or explicit development direct OpenAI.
library;

import '../ai_outcome.dart';
import 'ai_proxy_request.dart';

abstract class AiTransport {
  Future<AiOutcome<Map<String, dynamic>>> execute(AiProxyRequest request);
}
