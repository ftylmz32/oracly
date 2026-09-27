/// Dream Phase 2.2 — false lexical evidence never reaches the provider and
/// never authorizes an AI image. Real service path; zero provider calls.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/dream_request_identity.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_facts.dart';
import 'package:oracly_new/features/dream/services/dream_analysis_guard.dart';
import 'package:oracly_new/features/dream/services/dream_grounding_words.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

import 'dream_phase21_support.dart';

const _collisions = 'Bir sunum yaptım. Dün çok yemek yedim. Evren çok büyüktü. '
    'İşaret yanıp sönüyordu. Ayrıca dışarı çıktım. Ateş yükseldi.';
const _genuine = 'Evdeydim. Kapıyı açtım. Denizde yüzüyordum. Bir kedi gördüm. '
    'Suya baktım. Ayı gördüm. Yediyi gördüm.';

DreamAnalysisFacts facts(String told, String language) =>
    DreamAnalysisFacts.from(
      narrative: told,
      understanding: DreamUnderstandingService()
          .build(narrative: told, language: language),
      language: language,
    );

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('TR provider payload carries no look-alike symbol', () async {
    final (ctx, _, _) = await send(_collisions, app: 'tr');
    final symbols = payloadOf(ctx)['symbols'] as List;
    for (final s in ['Su', 'Yedi', 'Ev', 'İş', 'Ay', 'At']) {
      expect(symbols, isNot(contains(s)));
    }
    expect(symbols, ['Ateş']);
  });

  test('TR provider payload keeps inflected real symbols', () async {
    final (ctx, _, _) = await send(_genuine, app: 'tr');
    expect(
      payloadOf(ctx)['symbols'],
      containsAll(['Ev', 'Kapı', 'Deniz', 'Kedi', 'Su', 'Ay', 'Yedi']),
    );
  });

  test('EN payload: no "at" from the Turkish lexicon, no prefix tokens',
      () async {
    final (ctx, _, _) = await send(
      'I tried to reduce the noise during a busy season at night; '
      'I read a catalogue.',
      app: 'en',
    );
    expect(payloadOf(ctx)['symbols'], isEmpty);
    final (real, _, _) =
        await send('I saw the red sea and two cats at night.', app: 'en');
    expect(payloadOf(real)['symbols'], unorderedEquals(['cat', 'red', 'sea']));
  });

  test('identity follows the corrected payload', () async {
    final (a, _, _) = await send('Bir sunum yaptım ve uyudum.', app: 'tr');
    final (b, _, _) = await send('Bir sunum yaptım ve uyudum.', app: 'tr');
    expect(payloadOf(a)['symbols'], isEmpty);
    expect(DreamRequestIdentity.fingerprint(a),
        DreamRequestIdentity.fingerprint(b));
    final (c, _, _) = await send('Bir sunum yaptım ve suya baktım.', app: 'tr');
    expect(payloadOf(c)['symbols'], ['Su']);
    expect(DreamRequestIdentity.fingerprint(c),
        isNot(DreamRequestIdentity.fingerprint(a)));
    expect(jsonEncode(payloadOf(a)), isNot(contains('"Su"')));
  });

  group('guard red team', () {
    const suText = 'Su, bu sahnede sessizce akan bir şey gibi duruyor; '
        'neyi taşıdığını merak edebilirsin.';
    const yediText = 'Yedi sayısı bu sahnede sakin bir düzen gibi duruyor; '
        'sana neyi hatırlattığını merak edebilirsin.';

    test('"sunum" never grounds an AI "Su"', () {
      final f = facts('Bir sunum hazırlıyordum.', 'tr');
      expect(DreamAnalysisGuard.isSpeakable(suText, f), isFalse);
      final real = facts('Bir sunum hazırlıyordum, suya baktım.', 'tr');
      expect(DreamAnalysisGuard.isSpeakable(suText, real), isTrue);
    });

    test('"yedim" never grounds an AI "Yedi"', () {
      final f = facts('Dün yemek yedim.', 'tr');
      expect(DreamAnalysisGuard.isSpeakable(yediText, f), isFalse);
      final real = facts('Dün yemek yedim, sonra yedi kapı gördüm.', 'tr');
      expect(DreamAnalysisGuard.isSpeakable(yediText, real), isTrue);
    });

    test('general grounding ignores a short accidental prefix', () {
      const text = 'Yedinci kattaki sessiz oda, uyanık bir bekleyişi '
          'anlatıyor gibi duruyor.';
      expect(
        DreamAnalysisGuard.isSpeakable(text, facts('Dün yemek yedim.', 'tr')),
        isFalse,
      );
    });

    test('general sameWord: inflection yes, accidental prefix no', () {
      bool same(String a, String b, String l) =>
          DreamGroundingWords.sameWord(a, b, l);
      expect(same('reduce', 'red', 'en'), isFalse);
      expect(same('season', 'sea', 'en'), isFalse);
      expect(same('catalogue', 'cat', 'en'), isFalse);
      expect(same('yedim', 'yedi', 'tr'), isFalse);
      expect(same('sunum', 'suyun', 'tr'), isFalse);
      expect(same('kapiyi', 'kapi', 'tr'), isTrue);
      expect(same('cats', 'cat', 'en'), isTrue);
      expect(same('окну', 'окно', 'ru'), isTrue);
    });

    test('EN "reduce" never grounds an AI "red"', () {
      const text = 'The red colour here feels quiet and steady; you might '
          'wonder what it asks of you.';
      final f = facts('I tried to reduce the noise.', 'en');
      expect(DreamAnalysisGuard.isSpeakable(text, f), isFalse);
      final real = facts('I tried to reduce the noise near a red wall.', 'en');
      expect(DreamAnalysisGuard.isSpeakable(text, real), isTrue);
    });
  });
}
