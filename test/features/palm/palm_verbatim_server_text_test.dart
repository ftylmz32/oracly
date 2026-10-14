/// The palm result shows the server-gated reading VERBATIM: the client never
/// rewrites a phrase and never drops a sentence. Only a structural failure
/// (empty / placeholder overall, key=value dump) is a failed analysis.
/// SYNTHETIC texts only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';

PalmReading _raw({
  String overall = 'Önümüzdeki aylarda haber alacaksın; uzun zamandır beklediğin biri hayatına girecek ve yeni fırsatlar gündeme gelebilir.',
  String heartLine = 'Kalp çizgin sonunda dallanıyor; bu, gönlünün iki yöne çekildiği bir dönem demektir.',
  String lifeLine = 'Hayat çizgin geniş bir kavisle dolaşıyor. Bu da enerjinin yüksek olduğunu gösteriyor.',
}) =>
    PalmReading(
      id: 'palm_v1',
      createdAt: DateTime(2026, 10, 12),
      hand: PalmHand.right,
      overall: overall,
      heartLine: heartLine,
      headLine: '',
      lifeLine: lifeLine,
      fateLine: '',
      takeaway: 'Önündeki yıl senin yılın.',
    );

void main() {
  test('server text is shown exactly: natural predictions and line wording are never rewritten or dropped', () {
    final raw = _raw();
    final composed = PalmFortuneComposer.compose(raw)!;
    expect(composed.overall, raw.overall);
    expect(composed.heartLine, raw.heartLine);
    expect(composed.lifeLine, raw.lifeLine);
    expect(composed.takeaway, raw.takeaway);
    expect(composed.fateLine, '');
  });

  test('a short "not visible" placeholder hides its section; a real sentence about a faint line is kept', () {
    final hidden = PalmFortuneComposer.compose(_raw(heartLine: 'Görülemiyor.'))!;
    expect(hidden.heartLine, '');
    const faint = 'Kader çizgin belirgin görünmüyor; bu da yolunu kendi ellerinle çizeceğin, kimsenin senin yerine karar veremeyeceği bir hayat anlatıyor.';
    expect(PalmFortuneComposer.compose(_raw(heartLine: faint))!.heartLine, faint);
  });

  test('safety net: only a lifespan / illness / death sentence is never shown', () {
    final r = PalmFortuneComposer.compose(_raw(lifeLine: 'Hayat çizgin geniş bir kavisle dolaşıyor. Bu, uzun bir ömür demek.'))!;
    expect(r.lifeLine, 'Hayat çizgin geniş bir kavisle dolaşıyor.');
  });

  test('only a structural failure is a failed analysis', () {
    expect(PalmFortuneComposer.compose(_raw(overall: '   ')), isNull);
    expect(PalmFortuneComposer.compose(_raw(overall: 'Kısa bir yorum.')), isNull);
    expect(PalmFortuneComposer.compose(_raw(overall: 'overall=avuç sakin; heartLine=uzun; lifeLine=kavisli; fateLine=yok')), isNull);
  });
}
