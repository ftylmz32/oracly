import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/features/tarot/presentation/widgets/card_selection/card_selection_deck.dart';

void main() {
  testWidgets('CardSelectionDeck selection rebuilds safely', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: CardSelectionDeck(
                selectedIndex: 3,
                sacred: 0.65,
                sacredLinear: 0.65,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  });
}
