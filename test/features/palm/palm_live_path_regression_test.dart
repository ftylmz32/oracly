/// Real frozen backend Palm output through the live client path. Proves the
/// client keeps what the backend wrote and never invents line meaning.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/presentation/palm_insight_copy.dart';

import 'palm_live_path_harness.dart';

const _batch3a2 = 'backend/tests/fixtures/batch3a/palm_live_3a2.json';
const _e3h = 'backend/tests/fixtures/e3h1/e3h_palm_live_negative.json';
const _batch3a4 = 'test/features/palm/fixtures/real/palm_real_batch3a4.json';

Map<String, dynamic> _batch3a4With(Map<String, String> lines) => {
      ...publicPalm(readJson(_batch3a4)['backend'] as Map<String, dynamic>),
      ...lines,
    };

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('A: Batch 3A.2 keeps its KALP lane ("yokluğundan")',
      (tester) async {
    final raw = publicPalm(readJson(_batch3a2)['narrative'] as Map<String, dynamic>);
    expect(raw['heartLine'], contains('yokluğundan'));
    final reading = composeLive(raw)!;
    expect(reading.heartLine, raw['heartLine']);
    await pumpSections(tester, reading);
    expect(find.text(PalmCopy.heartTitle), findsOneWidget);
    expect(renderedTexts(tester).join(' '), contains('yokluğundan'));
  });

  testWidgets('B: E3H keeps the ZİHİN sentence with "bölümünde"',
      (tester) async {
    final raw = publicPalm(readJson(_e3h));
    expect(raw['headLine'], contains('bölümünde'));
    final reading = composeLive(raw)!;
    expect(reading.headLine, raw['headLine']);
    await pumpSections(tester, reading);
    expect(
      renderedTexts(tester).any((t) => t.startsWith('Uzun, hafifçe aşağı kıvrılan')),
      isTrue,
    );
  });

  testWidgets('C: "Görülemiyor." never receives canned line meaning',
      (tester) async {
    final reading = composeLive(_batch3a4With({
      'heartLine': 'Görülemiyor.',
      'headLine': 'Görülemiyor.',
      'lifeLine': 'Görülemiyor.',
    }))!;
    expect([reading.heartLine, reading.headLine, reading.lifeLine], everyElement(isEmpty));
    await pumpSections(tester, reading);
    final shown = renderedTexts(tester).join('\n');
    for (final title in [PalmCopy.heartTitle, PalmCopy.headTitle, PalmCopy.lifeTitle]) {
      expect(find.text(title), findsNothing);
    }
    expect(shown, isNot(contains('Görülemiyor')));
    expect(shown, isNot(contains('Bu taraf bence')));
  });

  testWidgets('C: a short grounded line is shown as-is, nothing appended',
      (tester) async {
    const short = 'Baş çizgisi uzun ve düz ilerliyor.';
    final reading = composeLive(_batch3a4With({'headLine': short}))!;
    await pumpSections(tester, reading);
    expect(find.text(short), findsOneWidget);
    expect(renderedTexts(tester).where((t) => t.contains(short)), [short]);
  });

  testWidgets('C: clipboard never carries line meaning the UI does not show',
      (tester) async {
    final reading = composeLive(_batch3a4With({
      'heartLine': 'Görülemiyor.',
      'headLine': 'Baş çizgisi uzun ve düz ilerliyor.',
    }))!;
    await pumpSections(tester, reading);
    await expandAll(tester);
    final shown = renderedTexts(tester).join(' ');
    final copied = PalmInsightCopy.fromReading(reading);
    expect(copied, isNot(contains('Görülemiyor')));
    for (final block in copied.split('\n\n')) {
      final body = block.split('\n').skip(1).join(' ');
      for (final sentence in body.split(RegExp(r'(?<=[.!?])\s+'))) {
        expect(shown, contains(sentence));
      }
    }
  });

  testWidgets('D: "Bu ayrım" never renders alone after "dallanma" is removed',
      (tester) async {
    final reading = composeLive(_batch3a4With({
      'heartLine': 'Kalp çizgisinin ucunda küçük bir dallanma seçiliyor. '
          'Bu ayrım, duygularını iki yönde tarttığını düşündürüyor ve seçerken '
          'acele etmediğini gösteriyor.',
    }))!;
    expect(reading.heartLine, isEmpty);
    await pumpSections(tester, reading);
    expect(find.text(PalmCopy.heartTitle), findsNothing);
    expect(renderedTexts(tester).join(' '), isNot(contains('Bu ayrım')));
  });
}
