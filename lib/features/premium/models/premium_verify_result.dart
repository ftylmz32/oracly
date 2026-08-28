/// Server/store verification outcome — never inferred from a UI flag.
library;

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
  });

  final PremiumVerifyStatus status;
  final String? reason;

  bool get isActive => status == PremiumVerifyStatus.active;

  factory PremiumVerifyResult.active([String? reason]) => PremiumVerifyResult(
        status: PremiumVerifyStatus.active,
        reason: reason,
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
