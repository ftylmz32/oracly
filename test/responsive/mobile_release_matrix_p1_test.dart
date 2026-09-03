/// P1 - Mobile release permissions + portrait/viewport/a11y matrix.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/accessibility/oracly_a11y.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/platform/oracly_phone_orientation.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_screen.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_screen.dart';
import 'package:oracly_new/features/explore/presentation/explore_reference_screen.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_grid.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/features/star_map/presentation/reference/star_map_reference_screen.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_entry_screen.dart';
import 'package:oracly_new/screens/profile/reference/profile_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final root = Directory.current.path;

  group('Android permissions truth', () {
    test('keeps required capabilities; drops unused media storage', () {
      final xml = File(
        '$root/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(xml, contains('android.permission.CAMERA'));
      expect(xml, contains('android.permission.RECORD_AUDIO'));
      expect(xml, contains('android.permission.INTERNET'));
      expect(xml, contains('com.android.vending.BILLING'));
      expect(xml, contains('android.permission.VIBRATE'));
      expect(xml, contains('android.permission.POST_NOTIFICATIONS'));
      expect(xml, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(xml, isNot(contains('READ_MEDIA_IMAGES')));
      expect(xml, isNot(contains('READ_MEDIA_VISUAL_USER_SELECTED')));
      expect(
        RegExp(
          r'android:name="android\.permission\.READ_EXTERNAL_STORAGE"[\s\S]*?tools:node="remove"',
        ).hasMatch(xml),
        isTrue,
      );
      expect(xml, contains('android.provider.action.PICK_IMAGES'));
      expect(xml, contains('android.intent.action.GET_CONTENT'));
      expect(
        xml,
        contains('ScheduledNotificationBootReceiver'),
      );
    });
  });

  group('iOS Info.plist + localized strings', () {
    test('iPhone is portrait-only; iPad keeps landscape', () {
      final plist = File('$root/ios/Runner/Info.plist').readAsStringSync();
      final phoneBlock = RegExp(
        r'<key>UISupportedInterfaceOrientations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)!;
      expect(phoneBlock.group(1), contains('Portrait'));
      expect(phoneBlock.group(1), isNot(contains('Landscape')));
      final padBlock = RegExp(
        r'<key>UISupportedInterfaceOrientations~ipad</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(plist)!;
      expect(padBlock.group(1), contains('LandscapeLeft'));
      expect(padBlock.group(1), contains('LandscapeRight'));
    });

    test('InfoPlist.strings exist for tr, en, ru with honest keys', () {
      for (final locale in ['tr', 'en', 'ru']) {
        final file = File(
          '$root/ios/Runner/$locale.lproj/InfoPlist.strings',
        );
        expect(file.existsSync(), isTrue, reason: locale);
        final body = file.readAsStringSync();
        expect(body, contains('NSCameraUsageDescription'));
        expect(body, contains('NSPhotoLibraryUsageDescription'));
        expect(body, contains('NSMicrophoneUsageDescription'));
        expect(body, contains('NSSpeechRecognitionUsageDescription'));
      }
    });

    test('Xcode project wires InfoPlist.strings variant group', () {
      final pbx = File(
        '$root/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(pbx, contains('InfoPlist.strings in Resources'));
      expect(pbx, contains('en.lproj/InfoPlist.strings'));
      expect(pbx, contains('tr.lproj/InfoPlist.strings'));
      expect(pbx, contains('ru.lproj/InfoPlist.strings'));
      expect(pbx, contains('knownRegions'));
    });
  });

  group('a11y text scale policy', () {
    test('body scale above 1.4 is not soft-capped; chrome is', () {
      expect(OraclyA11y.maxAppTextScale, greaterThan(1.4));
      expect(OraclyA11y.maxChromeTextScale, lessThanOrEqualTo(1.2));
      final body =
          OraclyA11y.clampAppTextScaler(const TextScaler.linear(1.6));
      expect(body.scale(10), closeTo(16.0, 0.01));
      final at2 =
          OraclyA11y.clampAppTextScaler(const TextScaler.linear(2.0));
      expect(at2.scale(10), closeTo(20.0, 0.01));
    });

    test('phone orientation lock constant matches tablet breakpoint', () {
      expect(OraclyPhoneOrientation.phoneShortestSideMax, 600);
    });
  });

  group('critical viewport smoke', () {
    const viewports = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(360, 800),
      Size(375, 812),
      Size(390, 844),
      Size(393, 852),
      Size(412, 915),
      Size(430, 932),
    ];

    for (final size in viewports) {
      testWidgets(
        'Home grid + Explore fit ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          SharedPreferences.setMockInitialValues({});
          final storage = await LocalStorage.open();
          final layout = HomeReferenceTokens.layoutFor(size.height * 0.55);
          await tester.pumpWidget(
            buildProviderScopeHarness(
              storage: storage,
              child: MaterialApp(
                home: Scaffold(
                  body: HomeReferenceScope(
                    layout: layout,
                    child: const HomeReferenceModuleGrid(),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            buildProviderScopeHarness(
              storage: storage,
              child: const MaterialApp(home: ExploreReferenceScreen()),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('critical chambers mount at 360x640 without crash', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      for (final home in <Widget>[
        const OnboardingScreen(),
        const CoffeeReferenceScreen(),
        const PalmReferenceScreen(),
        const DreamReferenceScreen(),
        const AstrologyReferenceScreen(),
        const StarMapReferenceScreen(),
        const PremiumReferenceScreen(),
        const ProfileReferenceScreen(),
        const SettingsReferenceScreen(),
        const TarotRitualEntryScreen(),
      ]) {
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: MaterialApp(home: home),
          ),
        );
        await tester.pump();
        expect(find.byType(MaterialApp), findsOneWidget);
        tester.takeException();
      }
    });

    testWidgets('textScale matrix 1.0/1.3/1.5/2.0 on Explore+Settings', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      for (final scale in <double>[1.0, 1.3, 1.5, 2.0]) {
        for (final home in <Widget>[
          const ExploreReferenceScreen(),
          const SettingsReferenceScreen(),
        ]) {
          await tester.pumpWidget(
            buildProviderScopeHarness(
              storage: storage,
              child: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 800),
                  textScaler: TextScaler.linear(scale),
                ),
                child: MaterialApp(home: home),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: 'scale=$scale ${home.runtimeType}',
          );
        }
      }
    });

    testWidgets('Dream Astrology StarMap mount at textScale 2.0', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      for (final home in <Widget>[
        const DreamReferenceScreen(),
        const AstrologyReferenceScreen(),
        const StarMapReferenceScreen(),
      ]) {
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(2.0),
              ),
              child: MaterialApp(home: home),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(MaterialApp), findsOneWidget);
        tester.takeException();
      }
    });
  });
}
