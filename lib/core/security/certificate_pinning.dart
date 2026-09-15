/// Certificate pinning config — intentionally inactive (platform TLS only).
library;

/// Host + SPKI pin material. Reserved for a future real pinning design.
class PinnedCertificate {
  const PinnedCertificate({
    required this.host,
    required this.sha256Pins,
  });

  final String host;
  final List<String> sha256Pins;
}

abstract class CertificatePinningConfig {
  List<PinnedCertificate> get pinnedCertificates;
  bool get isEnabled;
}

/// R6 — pinning is intentionally unsupported. ApiClient uses ordinary
/// `http.Client` with OS certificate / hostname validation only.
///
/// Do not set [isEnabled] true without a real pinned transport wired into
/// ApiClient and an operational pin rotation plan.
class EnvironmentCertificatePinning implements CertificatePinningConfig {
  const EnvironmentCertificatePinning();

  @override
  bool get isEnabled => false;

  @override
  List<PinnedCertificate> get pinnedCertificates => const [];
}

/// Release/security readiness must not treat a config flag as enforcement.
abstract final class CertificatePinningReadiness {
  CertificatePinningReadiness._();

  /// True only when pinning is claimed **and** pin material exists.
  /// Today always false — ORACLY uses platform TLS only.
  static bool reportsActiveEnforcement([
    CertificatePinningConfig? config,
  ]) {
    final cfg = config ?? const EnvironmentCertificatePinning();
    return cfg.isEnabled && cfg.pinnedCertificates.isNotEmpty;
  }
}
