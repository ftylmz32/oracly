/// OR-1110 — Token usage tracking model.
library;

class TokenUsageSnapshot {
  const TokenUsageSnapshot({
    this.sessionTokens = 0,
    this.totalTokens = 0,
    this.requestCount = 0,
    this.estimatedCostUsd = 0,
  });

  final int sessionTokens;
  final int totalTokens;
  final int requestCount;
  final double estimatedCostUsd;

  TokenUsageSnapshot add(int tokens) {
    return TokenUsageSnapshot(
      sessionTokens: sessionTokens + tokens,
      totalTokens: totalTokens + tokens,
      requestCount: requestCount + 1,
      estimatedCostUsd: estimatedCostUsd + (tokens * 0.000002),
    );
  }
}
