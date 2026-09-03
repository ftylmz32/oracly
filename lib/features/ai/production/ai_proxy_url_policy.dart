/// Proxy URL policy — delegates to shared [ReleaseEndpointPolicy].
library;

import '../../../core/config/release_endpoint_policy.dart';

abstract final class AiProxyUrlPolicy {
  AiProxyUrlPolicy._();

  static bool rejectsDeveloperNetworking({
    required bool isDevelopment,
    required bool releaseLocked,
  }) =>
      ReleaseEndpointPolicy.rejectsDeveloperNetworking(
        isDevelopment: isDevelopment,
        releaseLocked: releaseLocked,
      );

  static bool isLoopbackUrl(String? raw) =>
      ReleaseEndpointPolicy.isLoopbackUrl(raw);

  static bool isPrivateOrLanUrl(String? raw) =>
      ReleaseEndpointPolicy.isPrivateOrLanUrl(raw);

  static bool isHttpsUrl(String? raw) => ReleaseEndpointPolicy.isHttpsUrl(raw);

  static String? sanitize({
    required String? raw,
    required bool isDevelopment,
    required bool releaseLocked,
  }) =>
      ReleaseEndpointPolicy.sanitize(
        raw: raw,
        isDevelopment: isDevelopment,
        releaseLocked: releaseLocked,
      );

  static bool rejectsLoopback({
    required bool isDevelopment,
    required bool releaseLocked,
  }) =>
      rejectsDeveloperNetworking(
        isDevelopment: isDevelopment,
        releaseLocked: releaseLocked,
      );
}