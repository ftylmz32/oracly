/// Encodes public share fields only. Extra JSON keys are ignored.
library;

import 'dart:convert';

import '../models/share_public_payload.dart';

abstract final class SharePayloadCodec {
  SharePayloadCodec._();

  static String encode(SharePublicPayload payload) {
    final raw = utf8.encode(jsonEncode(payload.toPublicJson()));
    return base64Url.encode(raw).replaceAll('=', '');
  }

  static SharePublicPayload? decode(String token) {
    if (token.isEmpty || token.length > 400) return null;
    if (token.contains('..')) return null;
    try {
      var padded = token;
      final pad = padded.length % 4;
      if (pad != 0) padded = padded.padRight(padded.length + (4 - pad), '=');
      final decoded = utf8.decode(base64Url.decode(padded));
      final json = jsonDecode(decoded);
      if (json is! Map) return null;
      return SharePublicPayload.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }
}
