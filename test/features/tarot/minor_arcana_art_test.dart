/// Minor Arcana artwork registry + Flutter chrome + asset load.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_content_catalogue.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/minor_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_major_card_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registry has exactly 56 minors matching catalogue paths', () {
    expect(MinorArcanaArt.allAssets, hasLength(56));
    expect(MinorArcanaArt.suits, hasLength(4));
    expect(MinorArcanaArt.rankStems, hasLength(14));
    final minors = TarotContentCatalogue.minorArcana;
    expect(minors, hasLength(56));
    expect(
      minors.map((c) => c.imageAsset).toSet(),
      MinorArcanaArt.allAssets.toSet(),
    );
    for (final card in minors) {
      expect(MinorArcanaArt.parse(card.imageAsset), isNotNull);
    }
  });

  test('major catalogue paths remain locked', () {
    final majors = TarotContentCatalogue.majorArcana;
    expect(majors, hasLength(22));
    for (var i = 0; i < 22; i++) {
      expect(majors[i].imageAsset, MajorArcanaArt.assetFor(i));
    }
  });

  test('all 56 scene assets exist and are non-empty', () {
    for (final asset in MinorArcanaArt.allAssets) {
      final f = File(asset);
      expect(f.existsSync(), isTrue, reason: asset);
      expect(f.lengthSync(), greaterThan(20 * 1024), reason: asset);
    }
  });

  test('rootBundle loads every minor asset', () async {
    for (final asset in MinorArcanaArt.allAssets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(20 * 1024), reason: asset);
    }
  });

  testWidgets('Flutter chrome renders minor numeral and suit title',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 300,
              child: TarotMajorCardArt(
                imageAsset:
                    'lib/assets/images/tarot/minor_arcana/wands/01_ace_wands.png',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('I'), findsOneWidget);
    expect(find.text('DEĞNEKLER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
