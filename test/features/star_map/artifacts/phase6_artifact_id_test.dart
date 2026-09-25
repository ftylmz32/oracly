/// Artifact id generation / validation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_id.dart';

void main() {
  tearDown(() {
    YildiznameArtifactId.generator = YildiznameArtifactId.secure;
  });

  test('id shape yid_<32 hex> and injectable generator', () {
    expect(YildiznameArtifactId.isValid('yid_0123456789abcdef0123456789abcdef'), isTrue);
    expect(YildiznameArtifactId.isValid('star-123'), isFalse);
    final id = YildiznameArtifactId.withGenerator(
      () => 'yid_ffffffffffffffffffffffffffffffff',
      YildiznameArtifactId.generate,
    );
    expect(id, 'yid_ffffffffffffffffffffffffffffffff');
    expect(YildiznameArtifactId.secure(), matches(r'^yid_[0-9a-f]{32}$'));
  });
}
