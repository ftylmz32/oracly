/// OR-1130 — Certificate pinning structure for production TLS.
library;

import '../config/app_config.dart';

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

class EnvironmentCertificatePinning implements CertificatePinningConfig {
  const EnvironmentCertificatePinning();

  @override
  bool get isEnabled =>
      AppConfig.isInitialized && AppConfig.instance.enableCertificatePinning;

  @override
  List<PinnedCertificate> get pinnedCertificates => const [
        PinnedCertificate(
          host: 'api.oracly.app',
          sha256Pins: [
            // Replace with production SPKI pins before release.
            'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
          ],
        ),
        PinnedCertificate(
          host: 'staging-api.oracly.app',
          sha256Pins: [
            'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
          ],
        ),
      ];
}

/// Hook point for HttpClient badCertificateCallback / native pinning layer.
abstract class CertificatePinValidator {
  bool validate(String host, List<int> certificateBytes);
}

class NoOpCertificatePinValidator implements CertificatePinValidator {
  @override
  bool validate(String host, List<int> certificateBytes) => true;
}
