/// The account a reading purchase is launched for, as the stores carry it.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class ReadingOwnerToken {
  /// A name-based UUID (version 5 layout, SHA-256 of the uid): StoreKit 2
  /// keeps the owner only as a UUID `appAccountToken` and silently drops
  /// any other string; Play keeps it as the obfuscated account id. The
  /// same uid always gives the same token, and it reveals nothing of it.
  static String forUid(String uid) {
    final bytes = sha256.convert(utf8.encode('oracly.reading.owner:$uid')).bytes.sublist(0, 16);
    bytes[6] = (bytes[6] & 0x0f) | 0x50;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// The token as a store echoes it back (StoreKit upper-cases UUIDs).
  static String? normalize(String? raw) {
    final value = raw?.trim().toLowerCase();
    return value == null || value.isEmpty ? null : value;
  }
}
