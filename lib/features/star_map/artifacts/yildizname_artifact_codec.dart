/// JSON codec for [YildiznameArtifact] — fail on unknown schema.
library;

import 'yildizname_artifact.dart';
import 'yildizname_artifact_exceptions.dart';
import 'yildizname_artifact_integrity.dart';
import 'yildizname_artifact_source.dart';

abstract final class YildiznameArtifactCodec {
  YildiznameArtifactCodec._();

  static Map<String, dynamic> toJson(YildiznameArtifact a) => {
        ...YildiznameArtifactIntegrity.canonicalMap(a),
        'contentHash': a.contentHash,
      };

  static YildiznameArtifact fromJson(Map<String, dynamic> json) {
    final schema = json['artifactSchemaVersion'];
    if (schema is! int) {
      throw const YildiznameArtifactCorruptException('schema missing');
    }
    if (schema != YildiznameArtifact.currentSchemaVersion) {
      throw YildiznameArtifactUnsupportedSchemaException('schema $schema');
    }
    final source = YildiznameArtifactSource.tryParse('${json['source']}');
    if (source == null) {
      throw const YildiznameArtifactCorruptException('source');
    }
    final createdRaw = json['createdAtUtc']?.toString();
    final created = createdRaw == null ? null : DateTime.tryParse(createdRaw);
    final payloadRaw = json['payload'];
    if (created == null ||
        payloadRaw is! Map ||
        (json['id']?.toString() ?? '').isEmpty ||
        (json['ownerId']?.toString() ?? '').isEmpty ||
        (json['contentHash']?.toString() ?? '').isEmpty ||
        (json['semanticDedupeKey']?.toString() ?? '').isEmpty) {
      throw const YildiznameArtifactCorruptException('required fields');
    }
    final artifact = YildiznameArtifact(
      artifactSchemaVersion: schema,
      id: '${json['id']}',
      ownerId: '${json['ownerId']}',
      createdAtUtc: created.toUtc(),
      source: source,
      resultLocale: json['resultLocale']?.toString(),
      scope: json['scope']?.toString(),
      fidelity: json['fidelity']?.toString(),
      calculationVersion: json['calculationVersion']?.toString(),
      interpretationVersion: json['interpretationVersion']?.toString(),
      resultContractVersion: json['resultContractVersion']?.toString(),
      serializerVersion: json['serializerVersion']?.toString(),
      policyVersion: json['policyVersion']?.toString(),
      evidenceFingerprint: json['evidenceFingerprint']?.toString(),
      semanticFingerprint: json['semanticFingerprint']?.toString(),
      contentHash: '${json['contentHash']}',
      semanticDedupeKey: '${json['semanticDedupeKey']}',
      payload: Map<String, dynamic>.from(payloadRaw),
    );
    YildiznameArtifactIntegrity.verify(artifact);
    return artifact;
  }

  /// Decode list entries; skip corrupt/unsupported without throwing.
  static List<YildiznameArtifact> decodeList(
    Iterable<Object?> entries, {
    void Function(String message)? onDiagnose,
  }) {
    final out = <YildiznameArtifact>[];
    for (final entry in entries) {
      try {
        if (entry is! Map) {
          onDiagnose?.call('skip non-map entry');
          continue;
        }
        out.add(fromJson(Map<String, dynamic>.from(entry)));
      } catch (e) {
        onDiagnose?.call('skip corrupt: $e');
      }
    }
    return out;
  }
}
