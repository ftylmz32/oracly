import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/features/tarot/presentation/widgets/tarot_home/oracly_sacred_identity.dart';

void main() {
  testWidgets('OraclySacredCornerOrnaments lays out with bounded stack constraints',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 121.7,
            height: 200,
            child: Stack(
              children: [
                ColoredBox(color: Colors.transparent),
                OraclySacredCornerOrnaments(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OraclySacredCornerOrnaments), findsOneWidget);
  });
}
