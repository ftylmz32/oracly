/// N1 — Settings: authoritative permission and the user-triggered test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/notification_permission.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/screens/settings/copy/settings_copy.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_test_fakes.dart';

const _testRow = 'Test bildirimi gönder';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late MemoryNotificationPort port;

  setUp(() async {
    SharedPreferences.setMockInitialValues(settingsTestLanguagePrefs);
    storage = LocalStorage(await SharedPreferences.getInstance());
    port = MemoryNotificationPort();
    OraclyL10n.bind('tr');
  });

  Future<void> pumpSettings(WidgetTester tester, {bool enabled = false}) async {
    if (enabled) {
      SharedPreferences.setMockInitialValues({
        ...settingsTestLanguagePrefs,
        'settings_notifications': true,
      });
      storage = LocalStorage(await SharedPreferences.getInstance());
    }
    await tester.binding.setSurfaceSize(const Size(390, 3200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
          oraclyNotificationPortProvider.overrideWithValue(port),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SettingsReferenceScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapToggle(WidgetTester tester) async {
    await tester.ensureVisible(find.text(SettingsCopy.notificationsTitle));
    await tester.tap(
      find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
    );
    await settle(tester);
  }

  testWidgets('first-time iPhone flow: system prompt accepted → scheduled', (
    tester,
  ) async {
    port
      ..permissionOverride = NotificationPermissionStatus.notDetermined
      ..statusAfterRequest = NotificationPermissionStatus.granted;
    await pumpSettings(tester);
    await tapToggle(tester);
    await tester.tap(find.text('İzin Ver'));
    await settle(tester);

    expect(port.permissionRequests, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_notifications'), isTrue);
    expect(port.scheduled?.kind, OraclyNotificationKind.daily);
  });

  testWidgets('refused prompt keeps the switch off and offers OS settings', (
    tester,
  ) async {
    port
      ..permissionOverride = NotificationPermissionStatus.notDetermined
      ..statusAfterRequest = NotificationPermissionStatus.permanentlyDenied;
    await pumpSettings(tester);
    await tapToggle(tester);
    await tester.tap(find.text('İzin Ver'));
    await settle(tester);

    expect(
      find.text(OraclyL10n.t('notif.permission_permanent_body')),
      findsOneWidget,
    );
    expect(find.text(OraclyL10n.t('notif.permission_settings_label')), findsOneWidget);
    await tester.tap(find.text(OraclyL10n.t('notif.permission_later')));
    await settle(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_notifications') ?? false, isFalse);
    expect(port.scheduled, isNull);
  });

  testWidgets('test row is shown only while notifications are on', (
    tester,
  ) async {
    await pumpSettings(tester);
    expect(find.text(_testRow), findsNothing);
  });

  testWidgets('user tap posts one test notification and confirms it', (
    tester,
  ) async {
    await pumpSettings(tester, enabled: true);
    await tester.ensureVisible(find.text(_testRow));
    expect(port.shown, isEmpty, reason: 'never sent without a tap');
    await tester.tap(find.text(_testRow));
    await settle(tester);

    expect(port.shown, hasLength(1));
    expect(port.shown.single.body, 'Bildirimler bu cihazda çalışıyor.');
    expect(find.text('Test bildirimi gönderildi.'), findsOneWidget);
  });

  testWidgets('a failed test post is reported, never as sent', (tester) async {
    port.showShouldFail = true;
    await pumpSettings(tester, enabled: true);
    await tester.ensureVisible(find.text(_testRow));
    await tester.tap(find.text(_testRow));
    await settle(tester);

    expect(find.text('Test bildirimi gösterilemedi. Lütfen tekrar dene.'), findsOneWidget);
    expect(find.text('Test bildirimi gönderildi.'), findsNothing);
  });

  testWidgets('test after OS permission was revoked explains instead of '
      'pretending', (tester) async {
    await pumpSettings(tester, enabled: true);
    port.permissionOverride = NotificationPermissionStatus.permanentlyDenied;
    await tester.ensureVisible(find.text(_testRow));
    await tester.tap(find.text(_testRow));
    await settle(tester);

    expect(port.shown, isEmpty);
    expect(
      find.text(OraclyL10n.t('notif.permission_permanent_body')),
      findsOneWidget,
    );
  });
}
