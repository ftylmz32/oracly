/// Server/store verification outcome — never inferred from a UI flag.
library;

/// Play's acknowledgement state of a verified, bound Android purchase, as
/// the backend reports it. Absent from older backends and other platforms.
enum PremiumStoreAcknowledgement {
  /// Play holds it acknowledged: the app must not acknowledge it.
  acknowledged,

  /// The backend's acknowledge failed and it retries; the app may
  /// acknowledge the now verified purchase itself.
  pending,
}

enum PremiumVerifyStatus {
  active,
  inactive,
  pending,
  unverified,
  expired,
  error,
}

class PremiumVerifyResult {
  const PremiumVerifyResult({
    required this.status,
    this.reason,
    this.acknowledgement,
  });

  final PremiumVerifyStatus status;
  final String? reason;

  /// Only meaningful with [isActive]; null when the backend did not say.
  final PremiumStoreAcknowledgement? acknowledgement;

  bool get isActive => status == PremiumVerifyStatus.active;

  factory PremiumVerifyResult.active([String? reason]) => PremiumVerifyResult(
        status: PremiumVerifyStatus.active,
        reason: reason,
      );

  /// Active, with the backend's report of Play's acknowledgement state.
  factory PremiumVerifyResult.verified(
    String? reason,
    PremiumStoreAcknowledgement? acknowledgement,
  ) => PremiumVerifyResult(
        status: PremiumVerifyStatus.active,
        reason: reason,
        acknowledgement: acknowledgement,
      );

  factory PremiumVerifyResult.inactive([String? reason]) => PremiumVerifyResult(
        status: PremiumVerifyStatus.inactive,
        reason: reason,
      );

  factory PremiumVerifyResult.pending([String? reason]) => PremiumVerifyResult(
        status: PremiumVerifyStatus.pending,
        reason: reason,
      );

  factory PremiumVerifyResult.unverified(String reason) => PremiumVerifyResult(
        status: PremiumVerifyStatus.unverified,
        reason: reason,
      );

  factory PremiumVerifyResult.expired([String? reason]) => PremiumVerifyResult(
        status: PremiumVerifyStatus.expired,
        reason: reason,
      );

  factory PremiumVerifyResult.error([String? reason]) => PremiumVerifyResult(
        status: PremiumVerifyStatus.error,
        reason: reason ?? 'verify_error',
      );
}
