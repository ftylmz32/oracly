/// Phase 7C / 7C.1 — settled spread geometry structural baselines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_projection.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_projection_validate.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_resolver.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_visual_kind.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slot_tile.dart';
import 'package:oracly_new/features/tarot/theme/tarot_tokens.dart';

import '../../features/tarot/narrative_shadow/narrative_shadow_test_support.dart';
import 'tarot_visual_harness.dart';

RevealCardData _card(int i) {
  final c = ritualCard(i);
  return RevealCardData(
    card: c,
    displayName: c.name,
    subtitle: 'upright',
    rarityLabel: 'Major',
    rarityColor: const Color(0xFFE8C872),
    imageAsset: c.image,
    isReversed: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  Future<void> pumpSlots(
    WidgetTester tester, {
    required Size viewport,
    required TarotSpreadType spread,
    required List<RevealCardData> placed,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: viewport),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RitualSpreadSlots(placed: placed, spread: spread),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void assertProjectedContained(TarotSpreadType type, double width) {
    final spec = TarotSpreadGeometryResolver.resolve(type);
    TarotSpreadGeometryProjectionValidate.assertContained(spec, width);
    TarotSpreadGeometryProjectionValidate.assertNoUnintendedOverlap(
      spec,
      width,
    );
  }

  for (final size in tarotVisualViewports) {
    final w = size.width;
    testWidgets(
      'threeCard complete @ ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpSlots(
          tester,
          viewport: size,
          spread: TarotSpreadType.threeCard,
          placed: [_card(0), _card(1), _card(2)],
        );
        expect(find.byType(RitualSpreadSlotTile), findsNWidgets(3));
        expect(tester.takeException(), isNull);
        assertProjectedContained(TarotSpreadType.threeCard, w - 32);
      },
    );

    testWidgets(
      'fiveCard complete @ ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpSlots(
          tester,
          viewport: size,
          spread: TarotSpreadType.fiveCard,
          placed: [for (var i = 0; i < 5; i++) _card(i)],
        );
        expect(find.byType(RitualSpreadSlotTile), findsNWidgets(5));
        expect(tester.takeException(), isNull);
        assertProjectedContained(TarotSpreadType.fiveCard, w - 32);
      },
    );

    testWidgets(
      'fiveDecision/crossroads @ ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpSlots(
          tester,
          viewport: size,
          spread: TarotSpreadType.crossroads,
          placed: [for (var i = 0; i < 5; i++) _card(i)],
        );
        expect(find.byType(RitualSpreadSlotTile), findsNWidgets(5));
        expect(tester.takeException(), isNull);
        assertProjectedContained(TarotSpreadType.crossroads, w - 32);
      },
    );
  }

  testWidgets('threeCard partial settled shows empty plates', (tester) async {
    await pumpSlots(
      tester,
      viewport: tarotVisualCanonicalViewport,
      spread: TarotSpreadType.threeCard,
      placed: [_card(0)],
    );
    expect(find.byType(RitualSpreadSlotTile), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('single renders no slot scaffold', (tester) async {
    await pumpSlots(
      tester,
      viewport: tarotVisualCanonicalViewport,
      spread: TarotSpreadType.single,
      placed: [_card(0)],
    );
    expect(find.byType(RitualSpreadSlotTile), findsNothing);
  });

  test('settled card size preserves ritual aspect ratio', () {
    const fieldW = 320.0;
    for (final kind in [
      TarotSpreadVisualKind.threeLinear,
      TarotSpreadVisualKind.fiveLinear,
      TarotSpreadVisualKind.fiveDecision,
    ]) {
      final h = TarotSpreadSettledProjection.fieldHeightFor(kind, fieldW);
      final size = TarotSpreadSettledProjection.cardSizeFor(
        kind: kind,
        fieldWidth: fieldW,
        fieldHeight: h,
      );
      expect(
        size.width / size.height,
        closeTo(TarotTokens.ritualCardAspectRatio, 0.001),
      );
    }
  });
}
