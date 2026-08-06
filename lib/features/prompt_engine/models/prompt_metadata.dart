/// OR-1160 — Metadata attached to prompt requests and responses.
library;

class PromptMetadata {
  const PromptMetadata({
    required this.templateId,
    required this.templateVersion,
    required this.domain,
    required this.createdAt,
    this.estimatedInputTokens = 0,
    this.estimatedOutputTokens = 0,
    this.estimatedCostUsd = 0,
    this.tags = const {},
    this.builderId,
  });

  final String templateId;
  final String templateVersion;
  final String domain;
  final DateTime createdAt;
  final int estimatedInputTokens;
  final int estimatedOutputTokens;
  final double estimatedCostUsd;
  final Map<String, String> tags;
  final String? builderId;

  PromptMetadata copyWith({
    int? estimatedInputTokens,
    int? estimatedOutputTokens,
    double? estimatedCostUsd,
  }) {
    return PromptMetadata(
      templateId: templateId,
      templateVersion: templateVersion,
      domain: domain,
      createdAt: createdAt,
      estimatedInputTokens: estimatedInputTokens ?? this.estimatedInputTokens,
      estimatedOutputTokens: estimatedOutputTokens ?? this.estimatedOutputTokens,
      estimatedCostUsd: estimatedCostUsd ?? this.estimatedCostUsd,
      tags: tags,
      builderId: builderId,
    );
  }
}
