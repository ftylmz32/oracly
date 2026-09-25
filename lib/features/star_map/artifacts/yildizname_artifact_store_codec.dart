/// Decode helpers for [LocalYildiznameArtifactRepository].
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'yildizname_artifact.dart';
import 'yildizname_artifact_codec.dart';

abstract final class YildiznameArtifactStoreCodec {
  YildiznameArtifactStoreCodec._();

  static List<YildiznameArtifact> decodeStringList(List<String> raw) {
    final maps = <Object?>[];
    for (final entry in raw) {
      try {
        maps.add(jsonDecode(entry));
      } catch (_) {
        debugPrint('[YildiznameArtifact] skip bad json entry');
      }
    }
    return YildiznameArtifactCodec.decodeList(
      maps,
      onDiagnose: (m) => debugPrint('[YildiznameArtifact] $m'),
    );
  }

  static YildiznameArtifact? tryDecode(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is! Map) return null;
      return YildiznameArtifactCodec.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  static String encode(YildiznameArtifact artifact) =>
      jsonEncode(YildiznameArtifactCodec.toJson(artifact));
}
