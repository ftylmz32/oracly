/// Where Fincan Haritası keeps a reading's photos, pins and notes: a
/// durable, app-private directory that the platform leaves out of device
/// backups — Android `Context.getNoBackupFilesDir()/coffee_cup_map`, iOS
/// `Library/Application Support/coffee_cup_map` with
/// `URLResourceValues.isExcludedFromBackup` set on the directory and on every
/// file written into it. The OS does not evict either location to free space.
///
/// Exclusion is answered by `MainActivity.kt` / `AppDelegate.swift` over
/// `app.oracly/cup_map_storage`. Tests replace [instance].
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

abstract class CoffeeCupMapLocation {
  const CoffeeCupMapLocation();

  static CoffeeCupMapLocation instance = const MethodChannelCoffeeCupMapLocation();

  /// The directory (created, itself excluded from backups).
  Future<Directory> directory();

  /// Marks one file inside [directory] as excluded from backups (iOS sets
  /// the resource value; on Android the whole directory already is).
  /// `false` when the path is not inside the directory.
  Future<bool> excludeFromBackup(String path);

  /// Reads the platform's answer back — the check every write relies on.
  Future<bool> isExcludedFromBackup(String path);
}

/// The directory is derived in Dart (no platform round trip for reads,
/// deletes or wipes); only backup exclusion crosses the bridge, and the
/// native side accepts a path only if it is inside the directory IT
/// computes — any mismatch answers `false`, so nothing is kept.
class MethodChannelCoffeeCupMapLocation extends CoffeeCupMapLocation {
  const MethodChannelCoffeeCupMapLocation();

  static const _channel = MethodChannel('app.oracly/cup_map_storage');
  static const dirName = 'coffee_cup_map';

  @override
  Future<Directory> directory() async {
    final Directory parent;
    if (Platform.isIOS) {
      // Library/Application Support.
      parent = await getApplicationSupportDirectory();
    } else if (Platform.isAndroid) {
      // getFilesDir()'s parent is the data dir; no_backup is
      // getNoBackupFilesDir().
      final files = await getApplicationSupportDirectory();
      parent = Directory(
        '${files.parent.path}${Platform.pathSeparator}no_backup',
      );
    } else {
      throw UnsupportedError('no cup map storage on this platform');
    }
    final dir = Directory('${parent.path}${Platform.pathSeparator}$dirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<bool> excludeFromBackup(String path) async =>
      await _channel.invokeMethod<bool>('excludeFromBackup', {'path': path}) ==
      true;

  @override
  Future<bool> isExcludedFromBackup(String path) async =>
      await _channel.invokeMethod<bool>(
        'isExcludedFromBackup',
        {'path': path},
      ) ==
      true;
}

/// `true` when this platform has no cup-map storage at all (desktop, web,
/// a test host): nothing can have been kept. A real failure to reach the
/// directory on a phone is never treated as "nothing there".
bool isCoffeeCupMapStorageMissing(Object error) => error is UnsupportedError;
