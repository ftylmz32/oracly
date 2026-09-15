/// Onboarding intro whisper — must not overflow on small screens or at
/// larger text scales. Regression test for the RenderFlex overflow that
/// occurred because [OnboardingPage] laid out its content in a plain
/// [Column] with `Spacer()`s instead of scrolling when content exceeded
/// the viewport (see OnboardingPage's LayoutBuilder + SingleChildScrollView
/// fix, matching BirthChartRecoveryScroll's established pattern).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    AppLocale.debugDeviceLocale = () => const Locale('tr');
  });

  tearDown(() => AppLocale.debugDeviceLocale = null);

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
  ];
  const textScales = <double>[1.0, 1.3];

  for (final size in viewports) {
    for (final scale in textScales) {
      testWidgets(
        'onboarding intro fits ${size.width.toInt()}x${size.height.toInt()} '
        '@ ${scale}x text scale',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          SharedPreferences.setMockInitialValues({});
          final storage = await LocalStorage.open();
          await tester.pumpWidget(
            buildProviderScopeHarness(
              storage: storage,
              child: MaterialApp(
                home: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: const OnboardingScreen(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(tester.takeException(), isNull);
          expect(find.text(OnboardingCopy.title), findsOneWidget);
          expect(find.text(OnboardingCopy.meetLabel), findsOneWidget);
        },
      );
    }
  }
}
