/// Immutable Yıldızname reading artifact — schema v1.
library;

import 'yildizname_artifact_source.dart';

final class YildiznameArtifact {
  YildiznameArtifact({
    required this.id,
    required this.ownerId,
    required this.createdAtUtc,
    required this.source,
    required this.contentHash,
    required this.semanticDedupeKey,
    required Map<String, dynamic> payload,
    this.resultLocale,
    this.scope,
    this.fidelity,
    this.calculationVersion,
    this.interpretationVersion,
    this.resultContractVersion,
    this.serializerVersion,
    this.policyVersion,
    this.evidenceFingerprint,
    this.semanticFingerprint,
    this.artifactSchemaVersion = 1,
  }) : payload = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(payload),
        );

  static const int currentSchemaVersion = 1;

  final int artifactSchemaVersion;
  final String id;
  final String ownerId;
  final DateTime createdAtUtc;
  final YildiznameArtifactSource source;
  final String? resultLocale;
  final String? scope;
  final String? fidelity;
  final String? calculationVersion;
  final String? interpretationVersion;
  final String? resultContractVersion;
  final String? serializerVersion;
  final String? policyVersion;
  final String? evidenceFingerprint;
  final String? semanticFingerprint;
  final String contentHash;
  final String semanticDedupeKey;
  final Map<String, dynamic> payload;
}
