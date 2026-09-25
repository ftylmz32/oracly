/// SHA-256 semantic fingerprint for Yıldızname Narrative V1.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'yildizname_narrative_request.dart';
import 'yildizname_request_canonical.dart';

abstract final class YildiznameRequestFingerprint {
  YildiznameRequestFingerprint._();

  static const keyPrefix = 'yildizname_narrative_v1_';

  /// Digest of canonical safe request — excludes attempt/owner/birth.
  static String of(YildiznameNarrativeRequest request) {
    final canonical = YildiznameRequestCanonical.encode(request);
    final digest = sha256.convert(utf8.encode(canonical));
    return '$keyPrefix${digest.toString()}';
  }

  /// Facts-only digest (themes excluded) for discovery invariance.
  static String factsOnly(YildiznameNarrativeRequest request) {
    final canonical = YildiznameRequestCanonical.encodeFactsOnly(request);
    final digest = sha256.convert(utf8.encode(canonical));
    return '$keyPrefix${digest.toString()}';
  }
}
