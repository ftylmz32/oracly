import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_stat_row.dart';
import 'package:oracly_new/features/home/reference/home_reference_header.dart';
import 'package:oracly_new/features/home/reference/home_reference_page.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  const viewports = <Size>[
    Size(360, 640),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(393, 852),
    Size(411, 901),
    Size(412, 915),
    Size(430, 932),
    Size(600, 960),
  ];

  double contentHeight(Size size, {double bottomSafe = 0}) {
    return size.height -
        HomeReferenceTokens.screenTop -
        (AppLayout.navBarHeight +
            AppLayout.navBarMarginBottom +
            bottomSafe +
            AppLayout.contentBottomBreath);
  }

  Widget wrapHome(Size size, double height, LocalStorage storage) {
    return buildProviderScopeHarness(
      storage: storage,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const Scaffold(body: HomeReferencePage()),
        ),
      ),
    );
  }

  group('Master Home — viewport fit, zero overflow', () {
    for (final size in viewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('full home stack fits at $label', (tester) async {
        final height = contentHeight(size, bottomSafe: 34);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await tester.pumpWidget(wrapHome(size, height, storage));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('ORACLY'), findsWidgets);
        expect(find.textContaining('OR'), findsWidgets);
        expect(find.text('Bugünün İzi'), findsOneWidget);
        expect(find.text('Bugünkü Enerjin'), findsNothing);
        expect(find.text('Kahve Falı'), findsOneWidget);
        expect(find.text('El Falı'), findsOneWidget);
        expect(find.text('Tarot'), findsOneWidget);
        expect(find.text('Ruh Eşi'), findsOneWidget);
        expect(find.text("Premium'a Geç"), findsWidgets);
        expect(find.text('Merhaba,'), findsOneWidget);
        expect(
          find.textContaining('Bugün senin için'),
          findsOneWidget,
        );
        expect(find.textContaining('İyi akşamlar'), findsNothing);
        expect(find.text(HomeReferenceHeader.tagline), findsNothing);
        expect(find.textContaining('Yolcu'), findsNothing);
        expect(find.textContaining('Hoş geldin'), findsNothing);
        expect(find.byType(ListView), findsNothing);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.textContaining('Premium'), findsWidgets);
      });
    }
  });

  testWidgets('hero ritual body copy renders exactly once', (tester) async {
    const size = Size(390, 844);
    final height = contentHeight(size, bottomSafe: 34);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(wrapHome(size, height, storage));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(DailyRitualCard), findsOneWidget);
    expect(find.text('Bugünün İzi'), findsOneWidget);
    final labels = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(DailyRitualCard),
        matching: find.byType(Text),
      ),
    );
    final bodies = labels
        .map((w) => w.data)
        .whereType<String>()
        .where(
          (s) =>
              s == DailyRitualReflections.welcome(
                OraclyUniverseState.current(),
              ) ||
              s == DailyRitualReflections.reflection(
                OraclyUniverseState.current(),
              ),
        )
        .toList();
    expect(bodies, hasLength(1));
  });

  group('Astrology stats — no overflow', () {
    testWidgets('stat row at 360 width', (tester) async {
      const size = Size(360, 800);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: Scaffold(
              body: AstrologyReferenceStatRow(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Yıldızname title — single line', () {
    testWidgets('YILDIZNAME does not wrap at 360', (tester) async {
      const size = Size(360, 800);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: Scaffold(
                body: StarMapReferenceAppBar(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
