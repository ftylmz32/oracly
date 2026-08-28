import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/voice/or_speech_text_preprocessor.dart';

void main() {
  test('markdown headings and bullets are not spoken', () {
    expect(
      OrSpeechTextPreprocessor.prepare('### Bugün dikkatimi çeken şey...'),
      'Bugün dikkatimi çeken şey...',
    );
    expect(
      OrSpeechTextPreprocessor.prepare('- Birinci\n- İkinci'),
      'Birinci\nİkinci',
    );
  });

  test('keeps ellipses for thought pauses', () {
    expect(
      OrSpeechTextPreprocessor.prepare('Bir dakika... burada ilginç bir şey var.'),
      'Bir dakika... burada ilginç bir şey var.',
    );
  });

  test('strips urls and decoration, not Turkish words', () {
    expect(
      OrSpeechTextPreprocessor.prepare('[kaynak](https://x.test) ve **metin**'),
      'kaynak ve metin',
    );
  });
}
