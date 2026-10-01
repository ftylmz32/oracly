/// Authoritative OS notification permission — one answer for iOS and Android.
///
/// iOS never goes through `permission_handler` here: without the
/// `PERMISSION_NOTIFICATIONS=1` Podfile macro its notification strategy is
/// compiled out and it reports `denied`/`permanentlyDenied` for every user,
/// even after they tapped Allow. The plugin that actually posts the
/// notification is the source of truth instead.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

enum NotificationPermissionStatus {
  /// Alerts are allowed.
  granted,

  /// iOS provisional (quiet) delivery — still delivered, so usable.
  provisional,

  /// Never asked yet; a request may show the system prompt.
  notDetermined,

  /// Refused, but the system prompt may still be shown again (Android).
  denied,

  /// Refused and the system will not prompt again — only OS Settings helps.
  permanentlyDenied,

  /// The platform could not answer (plugin/platform failure, unsupported OS).
  unavailable,
}

extension NotificationPermissionStatusX on NotificationPermissionStatus {
  bool get canDeliver =>
      this == NotificationPermissionStatus.granted ||
      this == NotificationPermissionStatus.provisional;

  bool get needsOsSettings =>
      this == NotificationPermissionStatus.permanentlyDenied;
}

/// Platform seam: tests drive every OS answer without a device plugin.
abstract class NotificationPermissionPlatform {
  Future<NotificationPermissionStatus> check();

  /// Shows the system prompt when the OS still allows it, then reports the
  /// resulting state. Never throws.
  Future<NotificationPermissionStatus> request();
}

class DeviceNotificationPermissionPlatform
    implements NotificationPermissionPlatform {
  DeviceNotificationPermissionPlatform(this._plugin, {TargetPlatform? platform})
    // ignore: prefer_initializing_formals
    : _platform = platform;

  final FlutterLocalNotificationsPlugin _plugin;
  final TargetPlatform? _platform;

  TargetPlatform get _os => _platform ?? defaultTargetPlatform;

  @override
  Future<NotificationPermissionStatus> check() async {
    if (kIsWeb) return NotificationPermissionStatus.unavailable;
    try {
      return switch (_os) {
        TargetPlatform.iOS => await _checkIos(),
        TargetPlatform.android => await _checkAndroid(),
        _ => NotificationPermissionStatus.unavailable,
      };
    } catch (e) {
      debugPrint('[ORACLY] notification permission check failed: $e');
      return NotificationPermissionStatus.unavailable;
    }
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    if (kIsWeb) return NotificationPermissionStatus.unavailable;
    try {
      switch (_os) {
        case TargetPlatform.iOS:
          final ios = _iosPlugin;
          if (ios == null) return NotificationPermissionStatus.unavailable;
          final allowed = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          if (allowed == true) return await _checkIos();
          // iOS shows its prompt once; a refusal can only be undone in
          // Settings, so there is no "ask again" state on this platform.
          final after = await _checkIos();
          return after.canDeliver
              ? after
              : NotificationPermissionStatus.permanentlyDenied;
        case TargetPlatform.android:
          final android = _androidPlugin;
          if (android == null) return NotificationPermissionStatus.unavailable;
          await android.requestNotificationsPermission();
          return await _checkAndroid();
        default:
          return NotificationPermissionStatus.unavailable;
      }
    } catch (e) {
      debugPrint('[ORACLY] notification permission request failed: $e');
      return NotificationPermissionStatus.unavailable;
    }
  }

  IOSFlutterLocalNotificationsPlugin? get _iosPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<NotificationPermissionStatus> _checkIos() async {
    final options = await _iosPlugin?.checkPermissions();
    if (options == null) return NotificationPermissionStatus.unavailable;
    if (options.isEnabled) {
      return options.isProvisionalEnabled && !options.isAlertEnabled
          ? NotificationPermissionStatus.provisional
          : NotificationPermissionStatus.granted;
    }
    return NotificationPermissionStatus.denied;
  }

  Future<NotificationPermissionStatus> _checkAndroid() async {
    // App-level "notifications enabled" covers both the Android 13+ runtime
    // permission and a user who switched ORACLY off in system settings.
    final enabled = await _androidPlugin?.areNotificationsEnabled();
    if (enabled == true) return NotificationPermissionStatus.granted;
    if (enabled == null) return NotificationPermissionStatus.unavailable;
    // permission_handler is reliable on Android (no compile-time macros).
    final status = await Permission.notification.status;
    if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    }
    // Granted runtime permission but disabled app notifications can only be
    // fixed in system settings.
    if (status.isGranted) return NotificationPermissionStatus.permanentlyDenied;
    return NotificationPermissionStatus.denied;
  }
}
