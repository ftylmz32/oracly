/// N1.1 — the UIScene notification delegate wiring must not silently vanish.
///
/// Source-verified against the locked plugins (firebase_messaging 16.6.0,
/// flutter_local_notifications 22.3.1):
/// - UIScene registers plugins after didFinishLaunchingWithOptions returns,
///   but the notification-center delegate must be set before it returns.
/// - flutter_local_notifications only receives callbacks relayed by
///   FlutterAppDelegate, so FlutterAppDelegate must own the delegate.
/// - firebase_messaging's configureNotificationCenterDelegate keeps an
///   existing FlutterAppLifeCycleProvider delegate (it then receives the
///   relayed calls); called FIRST it would take the delegate itself and
///   could not forward local-notification taps. So the order is fixed.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Line endings normalized: Windows checkouts use CRLF.
String _read(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');

void main() {
  final appDelegate = _read('ios/Runner/AppDelegate.swift');

  String didFinishLaunchingBody() {
    final start = appDelegate.indexOf('didFinishLaunchingWithOptions');
    final end = appDelegate.indexOf(
      'return super.application(application, didFinishLaunchingWithOptions',
      start,
    );
    expect(start, greaterThan(-1));
    expect(end, greaterThan(start));
    return appDelegate.substring(start, end);
  }

  test('FlutterAppDelegate owns the notification-center delegate before '
      'launch completes', () {
    expect(
      didFinishLaunchingBody(),
      contains(
        'UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate',
      ),
    );
  });

  test('Firebase Messaging is configured for UIScene, after the delegate is '
      'assigned and before super returns', () {
    final body = didFinishLaunchingBody();
    final assign = body.indexOf('UNUserNotificationCenter.current().delegate');
    final configure = body.indexOf(
      'FLTFirebaseMessagingPlugin.configureNotificationCenterDelegate()',
    );
    expect(configure, greaterThan(-1));
    expect(assign, lessThan(configure));
    expect(appDelegate, contains('import firebase_messaging'));
    expect(appDelegate, contains('import flutter_local_notifications'));
  });

  test('local-notification action isolate can reach plugins', () {
    final start = appDelegate.indexOf('didInitializeImplicitFlutterEngine');
    final body = appDelegate.substring(start);
    final callback = body.indexOf(
      'FlutterLocalNotificationsPlugin.setPluginRegistrantCallback',
    );
    final register = body.indexOf(
      'GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)',
    );
    expect(callback, greaterThan(-1));
    expect(register, greaterThan(callback));
  });

  test('the app really is UIScene + implicit engine + Swift Package Manager', () {
    expect(appDelegate, contains('FlutterImplicitEngineDelegate'));
    expect(_read('ios/Runner/SceneDelegate.swift'), contains('FlutterSceneDelegate'));
    final plist = _read('ios/Runner/Info.plist');
    expect(plist, contains('UIApplicationSceneManifest'));
    expect(plist, contains(r'$(PRODUCT_MODULE_NAME).SceneDelegate'));
    expect(
      _read('ios/Runner.xcodeproj/project.pbxproj'),
      contains('FlutterGeneratedPluginSwiftPackage'),
    );
    expect(File('ios/Podfile').existsSync(), isFalse);
  });

  test('FCM foreground presentation stays enabled', () {
    final bootstrap = _read('lib/core/notifications/reading_push_bootstrap.dart');
    expect(
      bootstrap,
      contains(
        'setForegroundNotificationPresentationOptions(\n'
        '        alert: true,\n'
        '        badge: true,\n'
        '        sound: true,',
      ),
    );
  });

  test('account deletion goes through the wipe that cancels notifications', () {
    expect(
      _read('lib/core/auth/account_deletion_finalizer.dart'),
      contains('UserLocalDataWipe.run('),
    );
    expect(
      _read('lib/core/auth/user_local_data_wipe.dart'),
      contains("await step('local_notifications', NotificationOwnerCleanup.run);"),
    );
  });
}
