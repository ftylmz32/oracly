/// What the client may honestly say about today's Coffee / Palm allowance.
///
/// There is no server read of the remaining allowance, so "available" is
/// never claimed: a free user sees the daily policy, and "used today" is
/// shown only after the server itself answered the daily quota. Premium is
/// the store-verified entitlement; the server re-checks it on every create.
library;

import '../../premium/models/premium_entitlement_state.dart';

enum ReadingAllowanceKind { coffee, palm }

enum ReadingAllowanceStatus {
  /// Membership is still being read: no claim either way.
  checking,

  /// Not a member: the daily free policy (1 a day, usual wait).
  free,

  /// Verified member: 2 a day in total, no wait.
  premium,

  /// The server answered the daily quota for this kind today.
  usedToday,

  /// Membership could not be read: the server decides at create.
  checkFailed,
}

class ReadingAllowanceView {
  const ReadingAllowanceView({
    required this.kind,
    required this.status,
    required this.premium,
  });

  final ReadingAllowanceKind kind;
  final ReadingAllowanceStatus status;

  /// Whether a verified membership is known (also while [usedToday]).
  final bool premium;

  /// The day's reading can be started from this screen.
  bool get canStart => status != ReadingAllowanceStatus.usedToday;
}

ReadingAllowanceView resolveReadingAllowance({
  required ReadingAllowanceKind kind,
  required bool loaded,
  required bool busy,
  required bool isPremium,
  required PremiumEntitlementState entitlement,
  required bool usedToday,
}) {
  final premium = loaded && isPremium;
  final ReadingAllowanceStatus status;
  if (usedToday) {
    status = ReadingAllowanceStatus.usedToday;
  } else if (premium) {
    status = ReadingAllowanceStatus.premium;
  } else if (!loaded || busy) {
    status = ReadingAllowanceStatus.checking;
  } else if (entitlement == PremiumEntitlementState.error) {
    status = ReadingAllowanceStatus.checkFailed;
  } else {
    status = ReadingAllowanceStatus.free;
  }
  return ReadingAllowanceView(kind: kind, status: status, premium: premium);
}

/// Only the exact server answer counts. Anything else (a 429 rate limit, a
/// 5xx, a lost connection, an unknown code) is never "used today".
bool isDailyQuotaAnswer(
  ReadingAllowanceKind kind, {
  required int? httpStatus,
  required String? backendCode,
}) {
  if (httpStatus != 429) return false;
  return backendCode ==
      (kind == ReadingAllowanceKind.coffee
          ? 'coffee_daily_quota'
          : 'palm_daily_quota');
}
