import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/transparency_copy.dart';
import 'package:oracly_new/features/insights/services/reflective_intelligence.dart';

void main() {
  group('TransparencyCopy', () {
    test('interpretation footnote avoids certainty language', () {
      expect(
        ReflectiveIntelligence.containsForbiddenTone(
          TransparencyCopy.interpretationFootnote,
        ),
        isFalse,
      );
      expect(
        TransparencyCopy.interpretationFootnote.toLowerCase(),
        contains('kehanet değil'),
      );
    });

    test('privacy intro states local ownership and limits', () {
      expect(
        TransparencyCopy.privacyIntro.toLowerCase(),
        contains('cihazında'),
      );
      expect(
        TransparencyCopy.privacyIntro.toLowerCase(),
        contains('profesyonel'),
      );
    });

    test('journal privacy reinforces user ownership', () {
      expect(
        TransparencyCopy.journalPrivacy.toLowerCase(),
        contains('sana ait'),
      );
    });
  });
}
