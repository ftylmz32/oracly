import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_personal_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/universe/oracly_ritual_time.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_stat_row.dart';
import 'package:oracly_new/features/home/reference/home_reference_header.dart';
import 'package:oracly_new/features/home/reference/home_reference_page.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:oracly_new/core/universe/oracly_universe_state.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_reflections.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_hero_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_or_flagship_copy.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  const fitViewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(393, 852),
    Size(411, 901),
    Size(412, 915),
    Size(430, 932),
    Size(600, 960),
  ];

  const scrollViewports = <Size>[Size(360, 640)];

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

  group('Master Home — hierarchy + safe overflow', () {
    for (final size in fitViewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('full home stack at $label', (tester) async {
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
        expect(find.text('Rüya Analizi'), findsOneWidget);
        expect(find.text(PremiumCopy.loadingBody), findsWidgets);
        expect(find.text(PremiumCopy.ctaBusy), findsWidgets);
        expect(find.text(PremiumCopy.ctaJoin), findsNothing);
        expect(
          find.text(
            HomePersonalCopy.greeting(
              time: OraclyRitualAtmosphere.fromHour(DateTime.now().hour),
            ),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Bugün senin için'), findsOneWidget);
        expect(find.text(HomeReferenceHeader.tagline), findsNothing);
        expect(find.textContaining('Yolcu'), findsNothing);
        expect(find.textContaining('Hoş geldin'), findsNothing);
        expect(find.byType(ListView), findsNothing);
        expect(find.textContaining('Premium'), findsWidgets);
      });
    }

    for (final size in scrollViewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('short home stack scrolls at $label', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await tester.pumpWidget(
          wrapHome(size, contentHeight(size, bottomSafe: 34), storage),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    }
  });

  group('Home copy remains readable without ellipsis', () {
    for (final width in <double>[320, 360, 390]) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('${width.toInt()}px at ${scale}x text', (tester) async {
          final size = Size(width, 844);
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          SharedPreferences.setMockInitialValues({});
          final storage = await LocalStorage.open();
          await tester.pumpWidget(
            buildProviderScopeHarness(
              storage: storage,
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: const Scaffold(body: HomeReferencePage()),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          final copyRoots = <Finder>[
            find.byType(HomeReferenceHeroCopy),
            find.byType(HomeReferenceOrFlagshipCopy),
            find.byType(DailyRitualHeroCopy),
          ];
          final meaningful = copyRoots.expand(
            (root) => tester.widgetList<Text>(
              find.descendant(of: root, matching: find.byType(Text)),
            ),
          );
          expect(meaningful, isNotEmpty);
          expect(
            meaningful.where((text) => text.overflow == TextOverflow.ellipsis),
            isEmpty,
          );
        });
      }
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
              s ==
                  DailyRitualReflections.welcome(
                    OraclyUniverseState.current(),
                  ) ||
              s ==
                  DailyRitualReflections.reflection(
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
            child: Scaffold(body: AstrologyReferenceStatRow()),
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
              child: Scaffold(body: StarMapReferenceAppBar()),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
