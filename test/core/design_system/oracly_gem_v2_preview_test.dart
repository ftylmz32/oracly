import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/oracly_gem_cluster.dart';
import 'package:oracly_new/core/design_system/oracly_gem_icon.dart';

void main() {
  const sizes = [20.0, 24.0, 32.0, 48.0, 64.0, 96.0, 120.0];

  for (final size in sizes) {
    testWidgets('gem paints at ${size.toInt()} px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF07040F),
            body: Center(child: OraclyGemIcon(size: size)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(OraclyGemIcon), findsOneWidget);
    });
  }

  testWidgets('cluster keeps one crystal identity', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OraclyGemCluster(count: 3, size: 48),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(OraclyGemIcon), findsNWidgets(3));
  });
}
