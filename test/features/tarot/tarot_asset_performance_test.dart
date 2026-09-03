import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/performance/oracly_decode_cache.dart';
import 'package:oracly_new/features/content/tarot/data/tarot_content_catalogue.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/art/tarot_card_asset.dart';
import 'package:oracly_new/features/tarot/art/tarot_image_budget.dart';
import 'package:oracly_new/features/tarot/art/tarot_major_card_art.dart';

void main() {
  test('preview is a thumbnail, full is not the whole deck', () {
    const png = 'lib/assets/images/tarot/major_arcana/00_deli.png';
    expect(TarotCardAsset.preview(png), contains('/thumbs/'));
    expect(TarotCardAsset.preview(png), endsWith('.webp'));
    expect(TarotCardAsset.full(png), isNot(contains('/thumbs/')));
    expect(TarotCardAsset.full(png), endsWith('.webp'));
    expect(TarotCardAsset.preview(png), isNot(TarotCardAsset.full(png)));
    expect(TarotCardAsset.previewCapPx, lessThan(TarotCardAsset.fullCapPx));
  });

  test('decode cap keeps fan thumbs small and reveal under 1536', () {
    expect(oraclyDecodeCachePx(48, 3, maxPx: TarotCardAsset.previewCapPx), 144);
    expect(oraclyDecodeCachePx(168, 3, maxPx: TarotCardAsset.fullCapPx), 504);
    expect(oraclyDecodeCachePx(4000, 3), 2048);
    expect(oraclyDecodeCachePx(4000, 3, maxPx: 512), 512);
  });

  test('tarot image budget does not keep 78 live bitmaps', () {
    expect(TarotImageBudget.liveLimit, lessThan(78));
  });

  testWidgets('tarot budget restores the previous image cache', (tester) async {
    final cache = PaintingBinding.instance.imageCache;
    final prevCount = cache.maximumSize;
    final prevBytes = cache.maximumSizeBytes;
    TarotImageBudget.enter();
    expect(cache.maximumSize, TarotImageBudget.liveLimit);
    expect(cache.maximumSizeBytes, TarotImageBudget.byteLimit);
    TarotImageBudget.leave();
    expect(cache.maximumSize, prevCount);
    expect(cache.maximumSizeBytes, prevBytes);
  });

  test('every catalogue face has full and thumb webp on disk', () {
    expect(TarotContentCatalogue.all, hasLength(78));
    for (final card in TarotContentCatalogue.all) {
      expect(File(TarotCardAsset.full(card.imageAsset)).existsSync(), isTrue);
      expect(File(TarotCardAsset.preview(card.imageAsset)).existsSync(), isTrue);
    }
    expect(File(TarotCardAsset.full(MajorArcanaArt.cardBack)).existsSync(), isTrue);
    expect(
      File(TarotCardAsset.preview(MajorArcanaArt.cardBack)).existsSync(),
      isTrue,
    );
  });

  testWidgets('history-style scroll never keeps 78 live images', (tester) async {
    TarotImageBudget.enter();
    addTearDown(TarotImageBudget.leave);
    final cards = TarotContentCatalogue.all;
    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: 72,
              child: TarotMajorCardArt(
                imageAsset: cards[index].imageAsset,
                showChrome: false,
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.fling(find.byType(ListView), const Offset(0, -3200), 3200);
    await tester.pump(const Duration(milliseconds: 400));
    final cache = PaintingBinding.instance.imageCache;
    expect(cache.maximumSize, TarotImageBudget.liveLimit);
    expect(cache.currentSize, lessThan(78));
  });

  test('pubspec bundles tarot webp only', () {
    final yaml = File('pubspec.yaml').readAsStringSync();
    expect(yaml.contains('- lib/assets/images/\n'), isFalse,
        reason: 'directory include ships unused tarot PNG masters');
    final listed = RegExp(
      r'^\s+- lib/assets/images/tarot/.+$',
      multiLine: true,
    ).allMatches(yaml).map((m) => m.group(0)!.trim());
    expect(listed, isNotEmpty);
    expect(listed.every((line) => line.endsWith('.webp')), isTrue);
    expect(listed.any((line) => line.endsWith('.png')), isFalse);
  });
}
