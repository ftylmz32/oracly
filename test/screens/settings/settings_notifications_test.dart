/// Bildirimler toggle is live, persisted, and off by default.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_kind.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/screens/settings/copy/settings_copy.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_screen.dart';
import 'package:oracly_new/screens/settings/reference/settings_reference_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late MemoryNotificationPort port;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    port = MemoryNotificationPort();
    OraclyL10n.bind('tr');
  });

  Future<void> pumpSettings(WidgetTester tester, {double width = 390}) async {
    await tester.binding.setSurfaceSize(Size(width, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          oraclyTtsProvider.overrideWithValue(SilentTts()),
          oraclySoundServiceProvider.overrideWithValue(SilentSound()),
          oraclyNotificationPortProvider.overrideWithValue(port),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(appThemeModeProvider);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: const SettingsReferenceScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Bildirimler is a real switch and defaults off', (tester) async {
    await pumpSettings(tester);
    expect(find.byType(SettingsReferenceSwitch), findsNWidgets(4));
    expect(find.text(SettingsCopy.notificationsTitle), findsOneWidget);
    expect(find.text(SettingsCopy.notificationsUnavailable), findsNothing);
    expect(port.scheduled, isNull);
  });

  testWidgets('persisted ON restores and schedules one daily invitation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'settings_notifications': true});
    storage = LocalStorage(await SharedPreferences.getInstance());
    await pumpSettings(tester);
    expect(port.scheduled?.kind, OraclyNotificationKind.daily);
    expect(port.scheduled?.body, isNot(contains('1995')));
    expect(port.scheduled?.body, isNot(contains('@')));
  });

  testWidgets('turning Bildirimler on asks once then schedules one', (
    tester,
  ) async {
    // The permission dialog action row wraps on narrow canvases; keep KN8 width.
    await pumpSettings(tester);
    await tester.ensureVisible(find.text(SettingsCopy.notificationsTitle));
    await tester.tap(
      find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('İzin Ver'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_notifications'), isTrue);
    expect(port.scheduled?.kind, OraclyNotificationKind.daily);
    expect(port.scheduled?.body, 'Bugünün mesajı hazır.');
  });

  testWidgets('turning Bildirimler off cancels the daily slot', (tester) async {
    SharedPreferences.setMockInitialValues({'settings_notifications': true});
    storage = LocalStorage(await SharedPreferences.getInstance());
    await pumpSettings(tester);

    await tester.ensureVisible(find.text(SettingsCopy.notificationsTitle));
    await tester.tap(
      find.byKey(ValueKey('settings-switch-${SettingsCopy.notificationsTitle}')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_notifications'), isFalse);
    expect(port.scheduled, isNull);
    expect(port.cancelCount, greaterThan(0));
  });
}
