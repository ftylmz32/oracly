import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/oracly_glass_card.dart';
import 'package:oracly_new/core/design_system/oracly_surface_depth.dart';
import 'package:oracly_new/core/design_system/oracly_surface_style.dart';
import 'package:oracly_new/widgets/glass_card.dart';

void main() {
  test('surface depth shadows stay multi-layer and bounded', () {
    final shadows = OraclySurfaceDepth.cardShadows(
      premium: true,
      selected: false,
      elevated: true,
      isLight: false,
    );
    expect(shadows.length, greaterThanOrEqualTo(3));
    for (final s in shadows) {
      expect(s.color.a, lessThanOrEqualTo(0.55));
    }
  });

  test('gold edge strengthens from base to selected', () {
    final base = OraclySurfaceDepth.goldEdge(
      selected: false,
      premium: false,
    );
    final premium = OraclySurfaceDepth.goldEdge(
      selected: false,
      premium: true,
    );
    final selected = OraclySurfaceDepth.goldEdge(
      selected: true,
      premium: false,
    );
    expect(base.a, lessThan(premium.a));
    expect(premium.a, lessThanOrEqualTo(selected.a));
    expect(
      OraclySurfaceDepth.goldEdgeWidth(selected: true, premium: false),
      greaterThan(
        OraclySurfaceDepth.goldEdgeWidth(selected: false, premium: false),
      ),
    );
  });

  test('premium fill includes gold wash stop', () {
    final colors = OraclySurfaceStyle.glassPremium.colors;
    expect(colors.length, greaterThanOrEqualTo(4));
  });

  testWidgets('GlassCard and OraclyGlassCard share one surface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GlassCard(child: Text('a')),
              OraclyGlassCard(child: Text('b')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(OraclyGlassCard), findsNWidgets(2));
  });
}
