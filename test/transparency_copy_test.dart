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
      expect(
        TransparencyCopy.interpretationFootnote.toLowerCase(),
        contains('yerel'),
      );
      expect(
        TransparencyCopy.interpretationFootnote.toLowerCase(),
        isNot(contains('yapay zek')),
      );
    });

    test('conversation caption is honest about local guidance', () {
      expect(
        TransparencyCopy.conversationCaption.toLowerCase(),
        contains('yerel'),
      );
      expect(
        TransparencyCopy.conversationCaption,
        contains('canlı model yanıtı değildir'),
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
