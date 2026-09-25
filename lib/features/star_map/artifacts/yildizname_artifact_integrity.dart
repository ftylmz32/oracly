/// SHA-256 contentHash over immutable artifact fields (excludes contentHash).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'yildizname_artifact.dart';
import 'yildizname_artifact_canonical.dart';
import 'yildizname_artifact_exceptions.dart';

abstract final class YildiznameArtifactIntegrity {
  YildiznameArtifactIntegrity._();

  static Map<String, dynamic> canonicalMap(YildiznameArtifact a) => {
        'artifactSchemaVersion': a.artifactSchemaVersion,
        'id': a.id,
        'ownerId': a.ownerId,
        'createdAtUtc': a.createdAtUtc.toUtc().toIso8601String(),
        'source': a.source.wireName,
        if (a.resultLocale != null) 'resultLocale': a.resultLocale,
        if (a.scope != null) 'scope': a.scope,
        if (a.fidelity != null) 'fidelity': a.fidelity,
        if (a.calculationVersion != null)
          'calculationVersion': a.calculationVersion,
        if (a.interpretationVersion != null)
          'interpretationVersion': a.interpretationVersion,
        if (a.resultContractVersion != null)
          'resultContractVersion': a.resultContractVersion,
        if (a.serializerVersion != null)
          'serializerVersion': a.serializerVersion,
        if (a.policyVersion != null) 'policyVersion': a.policyVersion,
        if (a.evidenceFingerprint != null)
          'evidenceFingerprint': a.evidenceFingerprint,
        if (a.semanticFingerprint != null)
          'semanticFingerprint': a.semanticFingerprint,
        'semanticDedupeKey': a.semanticDedupeKey,
        'payload': a.payload,
      };

  static String compute(YildiznameArtifact a) {
    final encoded = YildiznameArtifactCanonical.encode(canonicalMap(a));
    return sha256.convert(utf8.encode(encoded)).toString();
  }

  static void verify(YildiznameArtifact a) {
    if (compute(a) != a.contentHash) {
      throw const YildiznameArtifactCorruptException('contentHash mismatch');
    }
  }
}
