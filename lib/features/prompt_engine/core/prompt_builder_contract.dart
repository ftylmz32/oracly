/// OR-1160 — Builder contract for domain-specific prompt assembly.
library;

import '../models/prompt_context.dart';
import '../models/prompt_request.dart';
import 'prompt_domain.dart';

abstract class PromptBuilderContract<TInput> {
  PromptDomain get domain;
  String get builderId;
  String get templateId;

  PromptRequest build({
    required TInput input,
    required PromptContext context,
  });
}
