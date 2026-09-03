/// Shared HTTPS / anti-localhost policy for release-locked client endpoints.
library;

abstract final class ReleaseEndpointPolicy {
  ReleaseEndpointPolicy._();

  static bool rejectsDeveloperNetworking({
    required bool isDevelopment,
    required bool releaseLocked,
  }) =>
      releaseLocked || !isDevelopment;

  static bool isLoopbackUrl(String? raw) {
    final host = _hostOf(raw);
    if (host == null) return false;
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '0.0.0.0' ||
        host == '[::1]';
  }

  static bool isPrivateOrLanUrl(String? raw) {
    final host = _hostOf(raw);
    if (host == null || host.isEmpty) return false;
    if (isLoopbackUrl(raw)) return true;
    if (host.endsWith('.local')) return true;
    final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$')
        .firstMatch(host);
    if (ipv4 == null) return false;
    final a = int.tryParse(ipv4.group(1)!);
    final b = int.tryParse(ipv4.group(2)!);
    if (a == null || b == null) return false;
    if (a == 10) return true;
    if (a == 127) return true;
    if (a == 192 && b == 168) return true;
    if (a == 169 && b == 254) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    return false;
  }

  static bool isHttpsUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    try {
      return Uri.parse(trimmed).scheme.toLowerCase() == 'https';
    } catch (_) {
      return trimmed.toLowerCase().startsWith('https://');
    }
  }

  /// Empty / developer-only / non-HTTPS (when locked) → null (fail closed).
  static String? sanitize({
    required String? raw,
    required bool isDevelopment,
    required bool releaseLocked,
  }) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final locked = rejectsDeveloperNetworking(
      isDevelopment: isDevelopment,
      releaseLocked: releaseLocked,
    );
    if (!locked) return trimmed;
    if (isLoopbackUrl(trimmed)) return null;
    if (isPrivateOrLanUrl(trimmed)) return null;
    if (!isHttpsUrl(trimmed)) return null;
    if (trimmed.toLowerCase().contains('replace_with') ||
        trimmed.toLowerCase().contains('placeholder')) {
      return null;
    }
    return trimmed;
  }

  static String? _hostOf(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    try {
      return Uri.parse(trimmed).host.toLowerCase();
    } catch (_) {
      return null;
    }
  }
}