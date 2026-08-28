/// Long-form reading UX — readable at phone sizes, no clipping.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading_ux/reading_chapter.dart';
import 'package:oracly_new/core/reading_ux/reading_expand_section.dart';
import 'package:oracly_new/core/reading_ux/reading_long_form_scroll.dart';
import 'package:oracly_new/core/theme/reading_flow_text.dart';

const _phones = <Size>[
  Size(360, 800),
  Size(390, 844),
  Size(430, 932),
];

const _long = '''
İlk bakışta duran şey bir yol. Henüz acele etmeni istemiyor.

Sonra kalbinin yanında daha sessiz bir iz belirdi. Bunu bir sonuç gibi değil, bir duruş gibi okuyorum.

Üçüncü cümle işe dair. Kararın kendisi değil, kararın ardından kalacak his önemli.

Dördüncü paragraf kapanışa yaklaşıyor. Burada net olan, tempo değil, yön.
''';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('long copy splits into readable paragraphs', () {
    expect(ReadingFlowText.paragraphsOf(_long).length, greaterThan(2));
    expect(ReadingExpandSection.isLong(_long), isTrue);
  });

  for (final size in _phones) {
    testWidgets('reading fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadingLongFormScroll(
              kicker: 'Yorum',
              children: [
                ReadingChapter(body: _long, hero: true),
                ReadingExpandSection(title: 'Derinlik', body: _long),
                ReadingChapter(body: _long),
                ReadingChapter(body: _long),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('İlk bakışta'), findsWidgets);
      expect(find.text('Devamını oku'), findsOneWidget);

      await tester.tap(find.text('Devamını oku'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Dördüncü paragraf'), findsWidgets);
      expect(find.text('Devamını oku'), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pumpAndSettle();
      expect(find.text('Yorum'), findsOneWidget);
    });
  }
}
