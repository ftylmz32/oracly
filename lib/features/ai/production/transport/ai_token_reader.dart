/// Token suppliers for proxy transport — supports one forced refresh retry.
library;

typedef AiTokenReader = Future<String?> Function({bool forceRefresh});

/// App Attest's first-ever attestation on a fresh install genuinely takes
/// longer than a warm, cached token fetch — a real device round-trips to
/// Apple's attestation service and then exchanges that for a Firebase App
/// Check token. A photo-based reading (Coffee/Palm) is often the very first
/// AI feature a new install reaches (a prominent Home CTA), so it is
/// disproportionately likely to race a cold App Check attestation that a
/// later, warmed-up Tarot/chat call would no longer hit.
///
/// Both [AiProxyReadiness] and [ProxyAiHeaders] independently resolve the
/// App Check token before a proxy call; this is the one shared schedule both
/// funnel through so neither gives up on App Check sooner than the other —
/// a request that survives [AiProxyReadiness]'s check only to fail moments
/// later at header-building time (or vice versa) helps no one.
const appCheckRetryDelays = [
  Duration(milliseconds: 500),
  Duration(milliseconds: 1000),
];

/// Resolves an App Check token, retrying with a forced refresh after each
/// delay in [appCheckRetryDelays] until [reader] returns a non-empty value.
Future<String?> resolveAppCheckToken(AiTokenReader? reader) async {
  if (reader == null) return null;
  final first = (await reader(forceRefresh: false))?.trim();
  if (first != null && first.isNotEmpty) return first;
  for (final delay in appCheckRetryDelays) {
    await Future<void>.delayed(delay);
    final retried = (await reader(forceRefresh: true))?.trim();
    if (retried != null && retried.isNotEmpty) return retried;
  }
  return null;
}