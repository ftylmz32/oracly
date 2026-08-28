/// Major Arcana artwork registry + Flutter chrome + asset load.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_content_catalogue.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_card_back_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_major_card_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registry has exactly 22 majors + matching catalogue paths', () {
    expect(MajorArcanaArt.files, hasLength(22));
    expect(MajorArcanaArt.romans, hasLength(22));
    expect(MajorArcanaArt.titles, hasLength(22));
    expect(MajorArcanaArt.titles[0], 'DELİ');
    expect(MajorArcanaArt.titles[20], 'YARGI');
    expect(MajorArcanaArt.romans[21], 'XXI');
    final majors = TarotContentCatalogue.majorArcana;
    expect(majors, hasLength(22));
    for (var i = 0; i < 22; i++) {
      expect(majors[i].imageAsset, MajorArcanaArt.assetFor(i));
    }
  });

  test('all 22 scene assets and card back exist and are non-empty', () {
    for (final file in MajorArcanaArt.files) {
      final f = File('lib/assets/images/tarot/major_arcana/$file');
      expect(f.existsSync(), isTrue, reason: file);
      expect(f.lengthSync(), greaterThan(20 * 1024), reason: file);
    }
    final back = File('lib/assets/images/tarot/tarot_card_back.png');
    expect(back.existsSync(), isTrue);
    expect(back.lengthSync(), greaterThan(20 * 1024));
  });

  test('rootBundle loads every major asset and the card back', () async {
    for (var i = 0; i < 22; i++) {
      final data = await rootBundle.load(MajorArcanaArt.assetFor(i));
      expect(data.lengthInBytes, greaterThan(20 * 1024),
          reason: MajorArcanaArt.files[i]);
    }
    final back = await rootBundle.load(MajorArcanaArt.cardBack);
    expect(back.lengthInBytes, greaterThan(20 * 1024));
  });

  testWidgets('Flutter chrome renders roman numeral and Turkish title',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 300,
              child: TarotMajorCardArt(
                imageAsset: 'lib/assets/images/tarot/major_arcana/00_deli.png',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('DELİ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card back renders Oracly brand symbol', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 300,
              child: TarotCardBackArt(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('OR'), findsNothing);
    expect(find.text('ORACLY'), findsNothing);
    expect(find.bySemanticsLabel('ORACLY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
