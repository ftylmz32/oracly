/// Codec + integrity round-trip / fail-closed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_codec.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_exceptions.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_integrity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_legacy_section_kind.dart';

import 'phase6_test_support.dart';

void main() {
  tearDown(resetIds);

  test('codec round-trip and integrity verify', () {
    useFixedIds(const ['yid_cccccccccccccccccccccccccccccccc']);
    final a = YildiznameArtifactFactory.createLegacy(
      ownerId: 'o1',
      title: 'T',
      sections: sampleLegacySections(),
      sectionKind: YildiznameLegacySectionKind.skyMessage,
      locale: 'tr',
      dayKey: 'd',
    );
    YildiznameArtifactIntegrity.verify(a);
    final again = YildiznameArtifactCodec.fromJson(YildiznameArtifactCodec.toJson(a));
    expect(again.contentHash, a.contentHash);

    expect(
      () => YildiznameArtifactCodec.fromJson({
        ...YildiznameArtifactCodec.toJson(a),
        'artifactSchemaVersion': 99,
      }),
      throwsA(isA<YildiznameArtifactUnsupportedSchemaException>()),
    );

    final tampered = Map<String, dynamic>.from(YildiznameArtifactCodec.toJson(a));
    tampered['contentHash'] = 'deadbeef';
    expect(
      () => YildiznameArtifactCodec.fromJson(tampered),
      throwsA(isA<YildiznameArtifactCorruptException>()),
    );

    final list = YildiznameArtifactCodec.decodeList([
      YildiznameArtifactCodec.toJson(a),
      {'artifactSchemaVersion': 1},
      'bad',
    ]);
    expect(list, hasLength(1));
    expect(a, isA<YildiznameArtifact>());
  });
}
