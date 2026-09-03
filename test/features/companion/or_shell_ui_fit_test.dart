/// OR shell bottom inset — extendBody must not double-count nav chrome.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_app_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_input_bar.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_or_premium_dock.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_cta_unavailable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phones = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  const safeBottom = 34.0;
  const expectedClearance = AppLayout.navBarHeight +
      AppLayout.navBarMarginBottom +
      safeBottom +
      AppLayout.contentBottomBreath;

  Widget shellOr(Size size, {double keyboard = 0, double textScale = 1}) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(top: 47, bottom: safeBottom),
        viewPadding: const EdgeInsets.only(top: 47, bottom: safeBottom),
        viewInsets: EdgeInsets.only(bottom: keyboard),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        resizeToAvoidBottomInset: true,
        body: const CompanionReferenceScreen(),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.navBarMarginH,
            0,
            AppLayout.navBarMarginH,
            AppLayout.navBarMarginBottom + safeBottom,
          ),
          child: const SizedBox(
            height: AppLayout.navBarHeight,
            child: ColoredBox(color: Color(0x33FF0000)),
          ),
        ),
      ),
    );
  }

  Future<void> pumpShell(
    WidgetTester tester,
    Size size, {
    double keyboard = 0,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: shellOr(size, keyboard: keyboard, textScale: textScale),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('scrollBottomInset under shell matches single clearance',
      (tester) async {
    late double inset;
    late double inflatedPadding;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: safeBottom),
            viewPadding: EdgeInsets.only(top: 47, bottom: safeBottom),
          ),
          child: Scaffold(
            extendBody: true,
            body: Builder(
              builder: (context) {
                inflatedPadding = MediaQuery.paddingOf(context).bottom;
                inset = AppLayout.scrollBottomInset(context);
                return const SizedBox.expand();
              },
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                AppLayout.navBarMarginBottom + safeBottom,
              ),
              child: const SizedBox(height: AppLayout.navBarHeight),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(inflatedPadding, greaterThan(safeBottom));
    expect(inset, closeTo(expectedClearance, 0.5));
  });

  for (final size in phones) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('OR shell $label — header + no overflow', (tester) async {
      await pumpShell(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
    });

    testWidgets('OR shell $label keyboard 280 — no overflow', (tester) async {
      await pumpShell(tester, size, keyboard: 280);
      expect(tester.takeException(), isNull);
      expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
    });
  }

  testWidgets('OR shell short + textScale 1.5 — no overflow', (tester) async {
    await pumpShell(tester, const Size(360, 640), textScale: 1.5);
    expect(tester.takeException(), isNull);
    expect(find.byType(CompanionReferenceAppBar), findsOneWidget);
  });

  testWidgets('premium dock CTA clears shell nav without excess gap',
      (tester) async {
    const size = Size(360, 800);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late double dockBottomPad;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: EdgeInsets.only(top: 47, bottom: safeBottom),
            viewPadding: EdgeInsets.only(top: 47, bottom: safeBottom),
          ),
          child: Scaffold(
            extendBody: true,
            body: Column(
              children: [
                const Expanded(child: SizedBox.shrink()),
                Builder(
                  builder: (context) {
                    dockBottomPad = AppLayout.scrollBottomInset(context);
                    return const CompanionReferenceOrPremiumDock();
                  },
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                AppLayout.navBarMarginBottom + safeBottom,
              ),
              child: const SizedBox(height: AppLayout.navBarHeight),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(dockBottomPad, closeTo(expectedClearance, 0.5));
    final cta = find.text(CompanionCopy.orPaywallCta);
    final unavailable = find.byType(PremiumReferenceCtaUnavailable);
    expect(
      cta.evaluate().isNotEmpty || unavailable.evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('input bar bottom pad under shell is single clearance',
      (tester) async {
    const size = Size(390, 844);
    final input = TextEditingController();
    addTearDown(input.dispose);
    late double pad;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            padding: EdgeInsets.only(top: 47, bottom: safeBottom),
            viewPadding: EdgeInsets.only(top: 47, bottom: safeBottom),
          ),
          child: Scaffold(
            extendBody: true,
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Builder(
                builder: (context) {
                  pad = AppLayout.scrollBottomInset(context);
                  return CompanionReferenceInputBar(
                    controller: input,
                    onSend: () {},
                    onMicTap: () {},
                    onPlusTap: () {},
                  );
                },
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                AppLayout.navBarMarginBottom + safeBottom,
              ),
              child: const SizedBox(height: AppLayout.navBarHeight),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(pad, closeTo(expectedClearance, 0.5));
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}

