/// Canonical public legal document URLs — never invents placeholder domains.
library;

import '../config/oracly_runtime_config.dart';
import '../config/oracly_runtime_keys.dart';

abstract final class OraclyLegalUrls {
  OraclyLegalUrls._();

  static const privacyPolicyEnvKey = OraclyRuntimeKeys.privacyPolicyUrl;
  static const termsOfUseEnvKey = OraclyRuntimeKeys.termsOfUseUrl;

  /// Test-only source. Production reads dart-define + dotenv.
  static set testEnv(Map<String, String>? value) =>
      OraclyRuntimeConfig.testEnv = value;
  static Map<String, String>? get testEnv => OraclyRuntimeConfig.testEnv;

  static String? get privacyPolicyUrl =>
      OraclyRuntimeConfig.resolve().privacyPolicyUrl;
  static String? get termsOfUseUrl =>
      OraclyRuntimeConfig.resolve().termsOfUseUrl;

  static bool get hasPrivacyPolicy => privacyPolicyUrl != null;
  static bool get hasTermsOfUse => termsOfUseUrl != null;

  static Uri? get privacyPolicyUri {
    final raw = privacyPolicyUrl;
    return raw == null ? null : Uri.tryParse(raw);
  }

  static Uri? get termsOfUseUri {
    final raw = termsOfUseUrl;
    return raw == null ? null : Uri.tryParse(raw);
  }
}