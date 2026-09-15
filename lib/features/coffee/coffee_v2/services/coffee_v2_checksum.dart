/// Streaming SHA-256 for Coffee V2 staged assets — never reads a whole
/// file into memory merely to compute a checksum, and never reads all
/// three files at once to compare them.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';

abstract final class CoffeeV2Checksum {
  CoffeeV2Checksum._();

  static Future<String> sha256OfFile(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }
}
