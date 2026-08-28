import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_header.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  Future<void> pumpProfile(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 34),
          ),
          child: const MaterialApp(home: ProfileReferenceScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('profile hero and utility hierarchy without fake chrome', (
    tester,
  ) async {
    await pumpProfile(tester, const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text(ProfileCopy.screenTitle), findsOneWidget);
    expect(find.text('ALANIN'), findsOneWidget);
    expect(find.byType(ProfileReferenceHeader), findsOneWidget);
    expect(find.text(ProfileCopy.guestName), findsOneWidget);
    expect(find.text(ProfileCopy.spaceWhisper), findsOneWidget);
    expect(find.text(GemDisplay.format(0)), findsAtLeastNWidgets(1));
    expect(find.text(ProfileCopy.premiumMember), findsNothing);
    expect(find.text(ProfileCopy.premiumActive), findsNothing);
    expect(find.text('Başarılarım'), findsNothing);
    expect(find.text(ProfileCopy.newUserTitle), findsOneWidget);
    expect(find.text(ProfileCopy.orTitle, skipOffstage: false), findsOneWidget);
    expect(
      find.text(ProfileCopy.dailyMessageTitle, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(ProfileCopy.settingsTitle, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text(ProfileCopy.roomSection), findsOneWidget);
    expect(find.text(ProfileCopy.utilitySection), findsOneWidget);
    expect(find.text(ProfileCopy.journalTitle), findsWidgets);
    expect(find.text(ProfileCopy.gemsTitle), findsNothing);
    expect(find.text(ProfileCopy.historyTitle), findsNothing);
    expect(find.text(ProfileCopy.palmTitle), findsNothing);
    expect(find.text(ProfileCopy.insightsTitle), findsNothing);
    expect(find.text(ProfileCopy.notificationsTitle), findsNothing);
    expect(find.text(ProfileCopy.helpTitle), findsNothing);
    expect(find.text(ProfileCopy.logoutTitle), findsNothing);
    expect(find.textContaining('Yenileme:'), findsNothing);
    expect(find.textContaining('streak'), findsNothing);
    expect(find.textContaining('self knowledge'), findsNothing);
    expect(find.textContaining('Top 3%'), findsNothing);
    expect(find.textContaining('87%'), findsNothing);
  });

  group('Profile reference — no overflow', () {
    for (final size in viewports) {
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpProfile(tester, size);

        expect(tester.takeException(), isNull);
        expect(find.text('ALANIN'), findsOneWidget);
        expect(find.text(ProfileCopy.orTitle), findsOneWidget);
        expect(find.text(ProfileCopy.dailyMessageTitle), findsOneWidget);
        expect(find.text(ProfileCopy.settingsTitle), findsOneWidget);
        expect(find.text(ProfileCopy.logoutTitle), findsNothing);
      });
    }
  });
}
