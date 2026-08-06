/// OR-1160 — Token and cost estimation (no API calls).
library;

import '../models/prompt_request.dart';
import '../models/prompt_template.dart';

class TokenPricingConfig {
  const TokenPricingConfig({
    this.inputCostPer1k = 0.00015,
    this.outputCostPer1k = 0.0006,
    this.charsPerToken = 3.8,
  });

  final double inputCostPer1k;
  final double outputCostPer1k;
  final double charsPerToken;
}

class TokenEstimate {
  const TokenEstimate({
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.estimatedCostUsd,
  });

  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double estimatedCostUsd;
}

class TokenEstimationService {
  TokenEstimationService({this.pricing = const TokenPricingConfig()});

  final TokenPricingConfig pricing;

  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / pricing.charsPerToken).ceil();
  }

  TokenEstimate estimateForRequest(
    PromptRequest request, {
    int? expectedOutputTokens,
  }) {
    final inputTokens =
        estimateTokens('${request.system}${request.user}');
    final outputTokens = expectedOutputTokens ?? 800;
    final total = inputTokens + outputTokens;
    final cost = (inputTokens / 1000 * pricing.inputCostPer1k) +
        (outputTokens / 1000 * pricing.outputCostPer1k);

    return TokenEstimate(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: total,
      estimatedCostUsd: double.parse(cost.toStringAsFixed(6)),
    );
  }

  TokenEstimate estimateForTemplate(
    PromptTemplate template,
    PromptRequest request,
  ) =>
      estimateForRequest(
        request,
        expectedOutputTokens: template.expectedOutputTokens,
      );
}
