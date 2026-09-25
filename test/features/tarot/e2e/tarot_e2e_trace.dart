/// Phase 8 — deterministic E2E ceremony trace (test-only).
library;

/// Mutable counters + identity snapshots for one ritual lifecycle.
class TarotE2eTrace {
  String? sessionId;
  String? spread;
  int? shuffleSeed;
  final drawnCardIds = <int>[];
  final positionKeys = <String>[];
  final reversed = <bool>[];
  int drawCalls = 0;
  int settleCount = 0;
  int providerCalls = 0;
  final providerAttempts = <int>[];
  int chargeCommits = 0;
  int markProviderOk = 0;
  int journalSaves = 0;
  int? walletBefore;
  int? walletAfter;
  String? interpretationFingerprint;
  String? resultMode;
  String? interpretationSource;
  String? deliveryKind;
  String? historyReadingId;
  bool activeSessionPresent = false;

  Map<String, Object?> snapshot() => {
        'sessionId': sessionId,
        'spread': spread,
        'shuffleSeed': shuffleSeed,
        'drawnCardIds': List<int>.from(drawnCardIds),
        'positionKeys': List<String>.from(positionKeys),
        'reversed': List<bool>.from(reversed),
        'drawCalls': drawCalls,
        'settleCount': settleCount,
        'providerCalls': providerCalls,
        'providerAttempts': List<int>.from(providerAttempts),
        'chargeCommits': chargeCommits,
        'markProviderOk': markProviderOk,
        'journalSaves': journalSaves,
        'walletBefore': walletBefore,
        'walletAfter': walletAfter,
        'interpretationFingerprint': interpretationFingerprint,
        'resultMode': resultMode,
        'interpretationSource': interpretationSource,
        'deliveryKind': deliveryKind,
        'historyReadingId': historyReadingId,
        'activeSessionPresent': activeSessionPresent,
      };
}
