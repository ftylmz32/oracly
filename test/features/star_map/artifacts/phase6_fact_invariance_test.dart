/// K — Memory themes must not alter facts-only fingerprint.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_request_fingerprint.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import 'phase6_test_support.dart';

void main() {
  test('K facts-only fingerprint invariant under theme change', () {
    final base = sampleRequest(themes: const []);
    final withThemes = sampleRequest(
      themes: const [
        YildiznameThemeFact(themeRef: 'theme.x', label: 'X'),
        YildiznameThemeFact(themeRef: 'theme.y', label: 'Y'),
      ],
    );
    expect(
      YildiznameRequestFingerprint.factsOnly(base),
      YildiznameRequestFingerprint.factsOnly(withThemes),
    );
    expect(
      YildiznameRequestFingerprint.of(base),
      isNot(YildiznameRequestFingerprint.of(withThemes)),
    );
  });
}
