/// Last-line redaction for store diagnostics text.
///
/// The formatter only reads whitelisted typed fields; this guards the few
/// free-text ones (store error message, exception type names, product ids)
/// against anything shaped like a credential, payload or identity.
library;

abstract final class StoreDiagnosticsRedaction {
  StoreDiagnosticsRedaction._();

  static const redacted = '[redacted]';

  static final _pem = RegExp(
    r'-----BEGIN[^-]*-----[\s\S]*?(-----END[^-]*-----|$)',
  );
  static final _jws = RegExp(r'eyJ[A-Za-z0-9_\-]+(\.[A-Za-z0-9_\-]*)*');
  static final _bearer = RegExp(r'bearer\s+\S+', caseSensitive: false);
  static final _keyValue = RegExp(
    r'(token|receipt|signature|authorization|password|secret|api[_\-]?key|'
    r'verification[_\-]?data|jws|jwt|transaction[_\-]?id|'
    r'app[_\-]?account[_\-]?token|issuer[_\-]?id|key[_\-]?id)'
    r'''\s*["']?\s*[:=]\s*["']?[^\s,;"']+''',
    caseSensitive: false,
  );
  static final _openAiKey = RegExp(r'sk-[A-Za-z0-9_\-]{8,}');
  static final _uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}',
  );
  static final _email = RegExp(r'[\w.+\-]+@[\w\-]+\.[\w.\-]+');
  static final _opaque = RegExp(r'[A-Za-z0-9+/=_\-]{32,}');
  static final _longDigits = RegExp(r'\d{10,}');

  /// Redacts credential/payload/identity shapes, collapses whitespace and
  /// caps the result at [maxLength].
  static String scrub(String raw, {int maxLength = 160}) {
    var text = raw
        .replaceAll(_pem, redacted)
        .replaceAll(_jws, redacted)
        .replaceAll(_bearer, redacted)
        .replaceAllMapped(_keyValue, (m) => '${m.group(1)}=$redacted')
        .replaceAll(_openAiKey, redacted)
        .replaceAll(_uuid, redacted)
        .replaceAll(_email, redacted)
        .replaceAll(_opaque, redacted)
        .replaceAll(_longDigits, redacted)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length > maxLength) text = '${text.substring(0, maxLength)}…';
    return text;
  }
}
