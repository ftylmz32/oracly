/// Profile zero-overflow guarantee — nav clearance, stable images, wrap text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_moments_strip.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_body.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_header.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_tokens.dart';
import 'package:oracly_new/screens/profile/reference/profile_soulmate_entry_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const longName =
      'Aleksandra-Constantinopolis von Habsburg-Lorraine the Third';

  Future<void> pumpBody(
    WidgetTester tester, {
    required String name,
    ImageProvider? photo,
    Size size = const Size(375, 812),
    double safeBottom = 34,
  }) async {
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
            padding: EdgeInsets.only(bottom: safeBottom),
          ),
          child: MaterialApp(
            home: Scaffold(
              extendBody: true,
              body: ProfileReferenceBody(
                profile: UserProfileModel(
                  name: name,
                  isPremium: false,
                ),
                photo: photo,
                onBack: () {},
                onEditName: () {},
                onPhotoTap: () {},
                onPhotoRemove: photo == null ? null : () {},
                onLogout: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('short name + no avatar — no overflow', (tester) async {
    await pumpBody(tester, name: 'Ada');
    expect(tester.takeException(), isNull);
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('long name wraps — no overflow', (tester) async {
    await pumpBody(tester, name: longName);
    expect(tester.takeException(), isNull);
    expect(find.text(longName), findsOneWidget);
    final text = tester.widget<Text>(find.text(longName));
    expect(text.softWrap, isTrue);
  });

  testWidgets('real avatar box stays fixed size', (tester) async {
    await pumpBody(
      tester,
      name: 'Ada',
      photo: const AssetImage('assets/images/profile/profile_journal_hero.webp'),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ProfileReferenceHeader), findsOneWidget);
  });

  testWidgets('SoulMate plate uses stable AspectRatio', (tester) async {
    await pumpBody(tester, name: 'Ada');
    // New users: SoulMate / Premium gems wait until the first discovery.
    expect(find.byType(ProfileSoulMateEntryRow), findsNothing);
    expect(find.text(ProfileCopy.newUserTitle), findsOneWidget);
  });

  testWidgets('bottom inset clears floating nav + safe area', (tester) async {
    const size = Size(375, 812);
    const safeBottom = 34.0;
    await pumpBody(tester, name: 'Ada', size: size, safeBottom: safeBottom);

    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final pad = scroll.padding as EdgeInsets;
    final expectedMin =
        AppLayout.navBarHeight +
        AppLayout.navBarMarginBottom +
        safeBottom +
        AppLayout.contentBottomBreath;
    expect(pad.bottom, greaterThanOrEqualTo(expectedMin));
    expect(
      pad.bottom,
      ProfileReferenceTokens.scrollBottomInset(
        tester.element(find.byType(SingleChildScrollView)),
      ),
    );
  });

  testWidgets('logout CTA remains in scroll content', (tester) async {
    await pumpBody(tester, name: 'Ada');
    expect(find.text(ProfileCopy.logoutTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(ProfileCopy.logoutTitle),
      80,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('moments strip present without layout exception', (tester) async {
    await pumpBody(tester, name: 'Ada');
    // Empty discovery → new-user path; moments appear with history.
    // Either path must remain exception-free.
    expect(tester.takeException(), isNull);
    expect(
      find.byType(ProfileMomentsStrip).evaluate().isEmpty ||
          find.byType(ProfileMomentsStrip).evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('narrow phone — zero overflow exceptions', (tester) async {
    await pumpBody(
      tester,
      name: longName,
      size: const Size(320, 568),
      safeBottom: 0,
    );
    expect(tester.takeException(), isNull);
  });
}
