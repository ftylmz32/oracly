/// PalmFortuneNarration is a standalone utility. It is NOT on the live Palm
/// result path (PalmResultSections) and must never be cited as evidence of
/// Palm product quality — see palm_live_path_regression_test.dart and
/// palm_real_fixture_freeze_test.dart for the live path.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_narration.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('utility: body keeps the overall and never re-adds a vision dump', () {
    final reading = PalmFortuneComposer.compose(
      PalmReading(
        id: 'valid',
        createdAt: DateTime(2026, 8, 18),
        hand: PalmHand.right,
        overall: 'Bu avuçta kararlar genelde sessizce, uzun bir düşünme '
            'süresinin ardından alınıyor gibi görünüyor; hızlı '
            'davranmak yerine oturup tartmayı tercih eden bir yapı bu.',
        heartLine: 'Kalp çizgisi belirgin.',
      ),
    )!;
    final spoken = PalmFortuneNarration.body(reading);
    expect(spoken, contains(reading.overall));
    expect(spoken, isNot(contains('Kalp = aşk')));
  });

  test('utility: body joins asides without empty gaps', () {
    final composed = PalmFortuneComposer.compose(
      PalmReading(
        id: 'p1',
        createdAt: DateTime(2026, 8, 15),
        hand: PalmHand.right,
        overall: 'El geniş ve belirgin çizgili; tempo hızlı değil, temkinli '
            'bir yapı hissettiriyor.',
        heartLine: 'Kalp çizgisinin belirgin yapısı.',
      ),
    )!;
    final spoken = PalmFortuneNarration.body(composed);
    expect(spoken, contains(composed.overall));
    expect(spoken, contains(composed.heartLine));
    expect(spoken, isNot(contains('\n\n\n')));
  });
}
