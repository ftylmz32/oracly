/// TASK 57 — Real-device portrait responsive QA (TECNO KN8 class).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/home/reference/home_reference_header.dart';
import 'package:oracly_new/features/home/reference/home_reference_page.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/features/tarot/presentation/epic031/tarot_epic031_page.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

/// TECNO KN8-class HD+ portrait canvases + common Android widths.
const _kn8Viewports = <Size>[
  Size(360, 720),
  Size(360, 800),
  Size(360, 640),
  Size(375, 812),
  Size(390, 844),
  Size(411, 901),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home header — large textScale must not overflow', () {
    for (final scale in const [1.0, 1.15, 1.3]) {
      testWidgets('header at 360x800 scale $scale', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        final layout = HomeReferenceTokens.layoutFor(700);
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: HomeReferenceScope(
                    layout: layout,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: HomeReferenceHeader(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Major screens — KN8 portrait, zero overflow', () {
    Future<void> pumpScreen(
      WidgetTester tester,
      Size size,
      Widget home, {
      double textScale = 1.0,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp(home: home),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    for (final size in _kn8Viewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('Home $label', (tester) async {
        await pumpScreen(tester, size, const HomeReferencePage());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Home $label textScale 1.3', (tester) async {
        await pumpScreen(
          tester,
          size,
          const HomeReferencePage(),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Astrology $label', (tester) async {
        await pumpScreen(tester, size, const AstrologyReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Yildizname $label', (tester) async {
        await pumpScreen(tester, size, const StarMapReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Premium $label', (tester) async {
        await pumpScreen(tester, size, const PremiumReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Coffee $label', (tester) async {
        await pumpScreen(tester, size, const CoffeeReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Palm $label', (tester) async {
        await pumpScreen(tester, size, const PalmReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Profile $label', (tester) async {
        await pumpScreen(tester, size, const ProfileReferenceScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('Tarot entry $label', (tester) async {
        await pumpScreen(tester, size, const TarotEpic031Page());
        expect(tester.takeException(), isNull);
      });
    }

    test('nav clearance stays above content breath', () {
      expect(AppLayout.navBarHeight, 60);
      expect(AppLayout.contentBottomBreath, greaterThan(0));
      expect(AppLayout.phoneWidths, contains(360));
    });
  });
}
