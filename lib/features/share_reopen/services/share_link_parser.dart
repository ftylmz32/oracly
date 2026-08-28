/// Reads a share URI. Query and fragment never affect access or payload.
library;

import 'share_payload_codec.dart';
import '../models/share_public_payload.dart';

abstract final class ShareLinkParser {
  ShareLinkParser._();

  static const scheme = 'oracly';
  static const httpsHost = 'oracly.app';

  static Uri build(SharePublicPayload payload) {
    final token = SharePayloadCodec.encode(payload);
    return Uri(scheme: scheme, host: 'share', path: '/$token');
  }

  static Uri? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == '/') return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final token = _token(uri);
    if (token == null) return null;
    if (SharePayloadCodec.decode(token) == null) return null;
    return Uri(scheme: scheme, host: 'share', path: '/$token');
  }

  static SharePublicPayload? payloadOf(Uri uri) {
    final token = _token(uri);
    if (token == null) return null;
    return SharePayloadCodec.decode(token);
  }

  static String? _token(Uri uri) {
    final path = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (uri.scheme == scheme && uri.host == 'share') {
      return path.isEmpty ? null : path.last;
    }
    if (path.length >= 2 && (path.first == 'share' || path.first == 's')) {
      return path[1];
    }
    if (uri.host == httpsHost && path.isNotEmpty) {
      if (path.first == 'share' || path.first == 's') {
        return path.length > 1 ? path[1] : null;
      }
    }
    if (uri.path.startsWith('/share/') || uri.path.startsWith('/s/')) {
      return path.isEmpty ? null : path.last;
    }
    return null;
  }
}
