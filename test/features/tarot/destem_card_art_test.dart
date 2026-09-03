/// Destem card art must show the full 512x896 face without crop.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/presentation/destem/destem_card_art.dart';
import 'package:oracly_new/features/tarot/presentation/destem/destem_card_detail_screen.dart';
import 'package:oracly_new/features/tarot/presentation/destem/destem_card_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleIds = [
    'major_00',
    'major_12',
    'cups_13',
    'swords_01',
  ];

  test('DestemCardArt uses canonical aspect ratio and contain fit', () {
    expect(DestemCardArt.artworkAspectRatio, closeTo(512 / 896, 0.0001));
  });

  testWidgets('representative cards preserve full artwork bounds', (tester) async {
    for (final id in sampleIds) {
      final card = OraclyTarotDeck.byId(id)!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: DestemCardArt(card: card)),
          ),
        ),
      );
      await tester.pump();

      final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspect.aspectRatio, DestemCardArt.artworkAspectRatio, reason: id);

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain, reason: id);

      final box = tester.renderObject<RenderBox>(
        find.byType(AspectRatio),
      );
      expect(box.size.width / box.size.height,
          closeTo(DestemCardArt.artworkAspectRatio, 0.01), reason: id);
      expect(tester.takeException(), isNull, reason: id);
    }
  });

  testWidgets('Destem grid tile and detail host uncropped card art', (tester) async {
    final card = OraclyTarotDeck.byId('major_12')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DestemCardTile(card: card, seen: false, onTap: () {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);

    await tester.pumpWidget(
      MaterialApp(
        home: DestemCardDetailScreen(card: card),
      ),
    );
    await tester.pump();
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
  });
}
