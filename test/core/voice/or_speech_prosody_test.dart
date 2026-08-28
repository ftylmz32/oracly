import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/oracly_format.dart';
import 'package:oracly_new/core/voice/or_speech_prosody.dart';
import 'package:oracly_new/core/voice/or_speech_text_preprocessor.dart';

void main() {
  setUpAll(() => OraclyFormat.ensureInitialized());

  test('visible chrome is stripped without rewriting meaning', () {
    expect(
      OrSpeechProsody.prepare('### Bugün dikkatimi çeken şey...'),
      'Bugün dikkatimi çeken şey...',
    );
  });

  test('short sentences gather into one thought', () {
    final spoken = OrSpeechProsody.prepare(
      'Burada bir yol var. Bir kuş var. Bu haber demek. Yakında olabilir.',
    );
    expect(spoken.contains('Burada bir yol var, bir kuş var'), isTrue);
    expect(spoken.split('.').where((p) => p.trim().isNotEmpty).length, lessThan(4));
  });

  test('a real thought pause stays a single ellipsis', () {
    expect(
      OrSpeechProsody.prepare('Bir dakika... burada gerçekten ilginç bir şey var.'),
      'Bir dakika... burada gerçekten ilginç bir şey var.',
    );
  });

  test('voice test phrases keep natural spoken rhythm', () {
    expect(
      OrSpeechProsody.prepare('Selam, bugün nasılsın?'),
      'Selam, bugün nasılsın?',
    );
    expect(
      OrSpeechProsody.prepare('Selam, bugün nasılsın.'),
      'Selam, bugün nasılsın?',
    );
    expect(
      OrSpeechProsody.prepare('Bugün iş konusunda biraz kararsızım.'),
      'Bugün iş konusunda biraz kararsızım.',
    );
    expect(
      OrSpeechProsody.prepare(
        'Bir dakika... burada gerçekten ilginç bir şey var.',
      ),
      'Bir dakika... burada gerçekten ilginç bir şey var.',
    );
    expect(
      OrSpeechProsody.prepare('Sen olsan ne yapardın?').endsWith('?'),
      isTrue,
    );
  });

  test('questions stay questions', () {
    expect(OrSpeechProsody.prepare('Sen olsan ne yapardın?').endsWith('?'), isTrue);
    expect(
      OrSpeechProsody.prepare('Gerçekten bunu istiyor musun?').contains('?'),
      isTrue,
    );
  });

  test('Turkish questions regain a rising mark', () {
    expect(
      OrSpeechProsody.prepare('Gerçekten bunu istiyor musun.').endsWith('?'),
      isTrue,
    );
    expect(OrSpeechProsody.prepare('Bu senin değil mi.').contains('?'), isTrue);
    expect(OrSpeechProsody.prepare('Nasıl hissediyorsun.').endsWith('?'), isTrue);
    expect(OrSpeechProsody.prepare('Onun ismi Ali.').contains('?'), isFalse);
    expect(OrSpeechProsody.prepare('Neden sonra kapı açıldı.').contains('?'), isFalse);
  });

  test('a paragraph break becomes one think pause', () {
    final spoken = OrSpeechProsody.prepare(
      'Birinci düşünce burada.\n\nİkinci düşünce ayrı durur.',
    );
    expect(spoken.contains('...'), isTrue);
    expect(spoken, contains('Birinci düşünce burada'));
    expect(spoken, contains('İkinci düşünce ayrı durur'));
  });

  test('spoken prepare is stable if run twice', () {
    const raw = 'Gerçekten bunu istiyor musun.\n\nBuradayım.';
    expect(OrSpeechProsody.prepare(OrSpeechProsody.prepare(raw)),
        OrSpeechProsody.prepare(raw));
  });

  test('section labels and percents become speakable', () {
    expect(OrSpeechProsody.prepare('### AŞK'), contains('Aşk tarafında'));
    expect(OrSpeechProsody.prepare('Bu %12 kadar.'), contains('yüzde 12'));
    expect(
      OrSpeechProsody.prepare('Tarih 17.08.2026.'),
      contains('17 Ağustos 2026'),
    );
  });

  test('long replies are shortened for voice only', () {
    final long = List.generate(
      12,
      (i) => 'Bu ayrıntılı bir gözlem cümlesi numarası ${i + 1}.',
    ).join(' ');
    final spoken = OrSpeechProsody.prepare(long);
    expect(spoken.length, lessThan(long.length));
    expect(spoken.length, lessThanOrEqualTo(OrSpeechProsody.maxSpokenChars + 40));
  });

  test('preprocessor still leaves the on-screen shape alone', () {
    expect(
      OrSpeechTextPreprocessor.prepare('- Birinci\n- İkinci'),
      'Birinci\nİkinci',
    );
  });
}
