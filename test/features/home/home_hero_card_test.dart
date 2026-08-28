import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/home/widgets/home_hero_card.dart';
import 'package:oracly_new/features/home/theme/home_focus.dart';

void main() {
  testWidgets('HomeHeroCard builds without layout errors', (tester) async {
    final presence = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 8),
    );
    addTearDown(presence.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeFocusScope(
          activeZone: HomeFocusZone.none,
          onActivate: (_) {},
          onRelease: () {},
          presence: presence,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: HomeHeroCard(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(HomeHeroCard), findsOneWidget);
  });
}
