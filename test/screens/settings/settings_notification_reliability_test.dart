/// RELIABILITY BATCH 2A — Fix 5: daily notification scheduling honesty.
///
/// A real scheduleDaily/cancelAll failure must be surfaced, never
/// swallowed — and a user-triggered enable must never show ON when the
/// schedule could not actually apply.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/settings/copy/settings_copy.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_test_fakes.dart' show settingsTestLanguagePrefs;

class _SilentSound extends OraclySoundService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> ensureSfxReady() async {}

  @override
  Future<OraclyApplyOutcome> syncAmbientEnabled(bool enabled) async =>
      OraclyApplyOutcome.success;

  @override
  Future<OraclyApplyOutcome> setAtmosphere(ZodiacSignId sign) async =>
      OraclyApplyOutcome.success;
}

class _SilentTts implements OraclyTtsPort {
  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => false;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));
  tearDown(() => OraclyL10n.bind('tr'));

  Future<void> pump({
    required WidgetTester tester,
    required LocalStorage storage,
    required MemoryNotificationPort port,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyTtsProvider.overrideWithValue(_SilentTts()),
          oraclySoundServiceProvider.overrideWithValue(_SilentSound()),
          oraclyNotificationPortProvider.overrideWithValue(port),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SettingsReferenceScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
    'successful schedule persists ON and reaches the real port',
    (tester) async {
      SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final port = MemoryNotificationPort();
      await pump(tester: tester, storage: storage, port: port);

      await tester.ensureVisible(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Permission rationale dialog — confirm.
      expect(find.text('İzin Ver'), findsOneWidget);
      await tester.tap(find.text('İzin Ver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_notifications'), isTrue);
      expect(port.scheduleCount, greaterThan(0));
      expect(find.text(ResilienceCopy.settingsNotificationApplyFailed), findsNothing);
    },
  );

  testWidgets(
    'a scheduling failure never leaves the toggle showing ON',
    (tester) async {
      SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final port = MemoryNotificationPort()..scheduleShouldFail = true;
      await pump(tester: tester, storage: storage, port: port);

      await tester.ensureVisible(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('İzin Ver'), findsOneWidget);
      await tester.tap(find.text('İzin Ver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      // Scheduling genuinely failed — never persisted as ON.
      expect(prefs.getBool('settings_notifications'), isFalse);
      expect(
        find.text(ResilienceCopy.settingsNotificationApplyFailed),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'FOLLOW-UP 2A: a cancellation failure never falsely claims OFF',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ...settingsTestLanguagePrefs,
        'settings_notifications': true,
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final port = MemoryNotificationPort()..cancelShouldFail = true;
      await pump(tester: tester, storage: storage, port: port);

      await tester.ensureVisible(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      await tester.pump();
      // Currently ON — tapping disables, no permission dialog involved.
      await tester.tap(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final prefs = await SharedPreferences.getInstance();
      // The schedule may still exist — cancelling was never proven to
      // have worked, so the honest state is ON, not a false OFF.
      expect(prefs.getBool('settings_notifications'), isTrue);
      final toggle = tester.widget<SettingsReferenceSwitch>(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      expect(toggle.value, isTrue);
      expect(
        find.text(ResilienceCopy.settingsNotificationApplyFailed),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a passive load-time re-sync failure never corrupts the visible switch '
    'and never crashes the screen',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ...settingsTestLanguagePrefs,
        'settings_notifications': true,
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      // The persisted preference is ON; the very first passive sync on
      // screen load will fail here — the switch must still honestly show
      // what the user last chose, not a silently-corrected OFF, and the
      // screen must not crash or show any snackbar for this passive path.
      final port = MemoryNotificationPort()..scheduleShouldFail = true;
      await pump(tester: tester, storage: storage, port: port);

      expect(tester.takeException(), isNull);
      final toggle = tester.widget<SettingsReferenceSwitch>(
        find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
      );
      expect(toggle.value, isTrue);
      expect(
        find.text(ResilienceCopy.settingsNotificationApplyFailed),
        findsNothing,
      );
    },
  );
}
