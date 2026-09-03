/// Soulmate experience final — real image, honest reading, cinematic reveal.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('pipeline stays on gpt-image-2 photoreal cinema', () {
    final transport = File('backend/src/ai/openai-transport.ts').readAsStringSync();
    final config = File('backend/src/config.ts').readAsStringSync();
    final service = File('backend/src/ai/service.ts').readAsStringSync();
    final prompt = File('backend/src/ai/soulmate-prompt.ts').readAsStringSync();
    expect(config, contains("gpt-image-2"));
    expect(config, contains('openaiImageModel'));
    expect(transport, contains('openaiImageModel'));
    // GPT Image returns b64_json by default; response_format is unsupported.
    expect(transport, isNot(contains("response_format: 'b64_json'")));
    expect(transport, contains('b64_json'));
    expect(service, contains('openaiImageSize'));
    expect(config, contains('1024x1536'));
    expect(prompt, contains('not a real person'));
    expect(prompt, contains('future partner'));
    expect(prompt, contains('Photorealistic cinematic portrait'));
    expect(prompt, contains('no porcelain'));
    expect(prompt, isNot(contains('dall-e')));
    expect(prompt, isNot(contains('painted character')));
    expect(prompt, isNot(contains('oil-paint')));
  });

  test('reading uses real inputs and never claims a soulmate arrival', () {
    final text = SoulMateInterpretation.forRequest(
      SoulMateDrawRequest(
        name: 'Ayşe',
        birthDate: DateTime(1994, 3, 12),
        gender: SoulMateGenderPref.feminine,
        intention: 'sakin bir bağ',
      ),
    );
    expect(text, contains('Ayşe'));
    expect(text.toLowerCase(), contains('sakin bir bağ'));
    expect(text.toLowerCase(), contains('ilkbahar'));
    expect(text, contains('Kadın'));
    expect(text, contains('Bu portrede ilk dikkatimi çeken'));
    expect(text.toLowerCase(), isNot(contains('kesin hayatına girecek')));
    expect(text.toLowerCase(), isNot(contains('hayatına girecek')));
    expect(text.toLowerCase(), isNot(contains('gerçek ruh eşi')));
    expect(text.toLowerCase(), isNot(contains('enerji')));
    expect(FortuneVoice.claimsCertainty(text), isFalse);
    expect(HumanReader.looksGeneric(text), isFalse);
    expect(SoulMateCopy.honesty.toLowerCase(), contains('sembolik'));
    expect(SoulMateCopy.honesty.toLowerCase(), contains('kesin ruh eşi'));
    expect(SoulMateCopy.screenLead.toLowerCase(), isNot(contains('gerçek bir eş iddiası')));
  });

  test('empty intention still names the person and skips invented arrival', () {
    final text = SoulMateInterpretation.forRequest(
      SoulMateDrawRequest(
        name: 'Deniz',
        birthDate: DateTime(1995, 8, 15),
      ),
    );
    expect(text, contains('Deniz'));
    expect(text.toLowerCase(), contains('yaz'));
    expect(text.toLowerCase(), isNot(contains('kadın')));
    expect(text.toLowerCase(), isNot(contains('kesin')));
  });
}
