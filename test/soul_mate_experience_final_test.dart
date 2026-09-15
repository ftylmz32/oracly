/// Soulmate experience final — generated image, honest symbolic reading.
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

  test('pipeline stays on gpt-image-2 premium graphite portrait', () {
    final transport = File('backend/src/ai/openai-transport.ts').readAsStringSync();
    final config = File('backend/src/config.ts').readAsStringSync();
    final service = File('backend/src/ai/service.ts').readAsStringSync();
    final prompt = File('backend/src/ai/soulmate-prompt.ts').readAsStringSync();
    final promptBuilder = File(
      'backend/src/ai/soulmate-portrait-prompt-builder.ts',
    ).readAsStringSync();
    final visualProfile = File(
      'backend/src/ai/soulmate-visual-profile.ts',
    ).readAsStringSync();
    expect(config, contains("gpt-image-2"));
    expect(config, contains('openaiImageModel'));
    expect(transport, contains('openaiImageModel'));
    // GPT Image returns b64_json by default; response_format is unsupported.
    expect(transport, isNot(contains("response_format: 'b64_json'")));
    expect(transport, contains('b64_json'));
    expect(service, contains('openaiImageSize'));
    expect(config, contains('1024x1536'));
    expect(prompt, contains('buildSoulmatePortraitPrompt'));
    expect(visualProfile, contains('fine refined graphite'));
    expect(promptBuilder, contains('premium graphite pencil portrait'));
    expect(promptBuilder, contains('not 3D'));
    expect(promptBuilder, contains('Strictly avoid 3D rendering, CGI'));
    expect(promptBuilder, contains('not a digital render'));
    expect(promptBuilder, contains('creative symbolic companion image'));
    expect(promptBuilder, contains('not a real person'));
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
