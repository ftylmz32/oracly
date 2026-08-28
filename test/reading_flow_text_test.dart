import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/theme/reading_flow_text.dart';

void main() {
  group('ReadingFlowText', () {
    test('splits explicit paragraph breaks', () {
      final paragraphs = ReadingFlowText.debugParagraphs('Bir cümle.\n\nİkinci paragraf.');
      expect(paragraphs.length, 2);
      expect(paragraphs.first, 'Bir cümle.');
      expect(paragraphs.last, 'İkinci paragraf.');
    });

    test('groups long single blocks into pairs of sentences', () {
      final paragraphs = ReadingFlowText.debugParagraphs(
        'Birinci cümle. İkinci cümle. Üçüncü cümle. Dördüncü cümle.',
      );
      expect(paragraphs.length, 2);
      expect(paragraphs.first, contains('Birinci'));
      expect(paragraphs.first, contains('İkinci'));
    });

    test('readingCompleteSentence adds terminal punctuation', () {
      expect(readingCompleteSentence('Sakin kal'), 'Sakin kal.');
      expect(readingCompleteSentence('Tamam.'), 'Tamam.');
      expect(readingCompleteSentence('Devam…'), 'Devam…');
    });
  });
}
