/// Fincan Haritası test fixtures: a path provider (V3 working dir, documents,
/// the pre-migration cache), a fake durable backup-excluded location that
/// behaves like the platform bridge, a real cup photo from the repo, and V3
/// photo assets built from real files with their real checksums.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_checksum.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_asset.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_work_files.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_location.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_photo_archive.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A real photo of a coffee cup already tracked in the repo.
const cupMapFixturePhoto = 'tool/matrix_evidence/test_coffee_cup.jpg';

String _norm(String path) =>
    File(path).absolute.path.replaceAll('\\', '/').toLowerCase();

/// Behaves like `app.oracly/cup_map_storage`: one durable directory; only an
/// existing file inside it can be marked excluded, and the answer is read
/// back from what was marked. [refuseExclusion] simulates a platform that
/// cannot exclude.
class FakeCupMapLocation extends CoffeeCupMapLocation {
  FakeCupMapLocation(this.root);
  final String root;
  bool refuseExclusion = false;
  final Set<String> _excluded = {};

  String get path =>
      '$root${Platform.pathSeparator}no_backup${Platform.pathSeparator}coffee_cup_map';

  bool _inside(String file) => _norm(file).startsWith('${_norm(path)}/');

  @override
  Future<Directory> directory() async {
    final dir = Directory(path);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<bool> excludeFromBackup(String file) async {
    if (refuseExclusion || !_inside(file) || !File(file).existsSync()) {
      return false;
    }
    _excluded.add(_norm(file));
    return true;
  }

  @override
  Future<bool> isExcludedFromBackup(String file) async =>
      File(file).existsSync() && _excluded.contains(_norm(file));

  /// Every file now in the directory, and whether each is marked excluded.
  Map<String, bool> audit() => {
        for (final f in Directory(path).existsSync()
            ? Directory(path).listSync().whereType<File>()
            : const <File>[])
          f.path: _excluded.contains(_norm(f.path)),
      };
}

class CupMapPaths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  CupMapPaths(this.root) : location = FakeCupMapLocation(root);
  final String root;
  final FakeCupMapLocation location;

  String get documents => '$root${Platform.pathSeparator}documents';

  /// The evictable cache directory (pre-migration Fincan Haritası photos).
  String get cache => '$root${Platform.pathSeparator}cache';

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;

  @override
  Future<String?> getTemporaryPath() async => root;

  @override
  Future<String?> getApplicationCachePath() async => cache;
}

/// The installed fake location (see [installCupMapPaths]).
FakeCupMapLocation get installedCupMapLocation =>
    CoffeeCupMapLocation.instance as FakeCupMapLocation;

/// Text of the map file (pins, notes), or `null` when none exists.
String? cupMapFileText() {
  final file = File(
    '${installedCupMapLocation.path}${Platform.pathSeparator}'
    '${CoffeeCupMapStore.fileName}',
  );
  return file.existsSync() ? file.readAsStringSync() : null;
}

Future<CupMapPaths> installCupMapPaths(Directory temp) async {
  final paths = CupMapPaths(temp.path);
  await Directory(paths.documents).create(recursive: true);
  PathProviderPlatform.instance = paths;
  CoffeeCupMapLocation.instance = paths.location;
  return paths;
}

Future<LocalStorage> ownedStorage(String ownerId) async {
  final storage = LocalStorage.ephemeral();
  await storage.setString(UserLocalDataIsolation.ownerKey, ownerId);
  return storage;
}

/// A kept photo in the cup-map archive, as the keeper would write it.
Future<String> keptCupMapPhoto(String readingId, CoffeeV3PhotoSlot slot) =>
    CoffeeCupMapPhotoArchive.persist(
      readingId: '${readingId}_cupmap_${slot.wireValue}',
      sourcePath: cupMapFixturePhoto,
    );

/// An app-owned V3 working copy of [source] for [slot], exactly as the V3
/// normalizer leaves it, with its real size and SHA-256.
Future<CoffeeV3PhotoAsset> v3WorkingAsset(
  String supportRoot,
  CoffeeV3PhotoSlot slot, {
  String source = cupMapFixturePhoto,
}) async {
  final dir = Directory('$supportRoot/${CoffeeV3WorkFiles.dirName}');
  await dir.create(recursive: true);
  final path =
      '${dir.path}/${CoffeeV3WorkFiles.filePrefix}${slot.wireValue}.jpg';
  await File(source).copy(path);
  return CoffeeV3PhotoAsset(
    slot: slot,
    path: path,
    mimeType: 'image/jpeg',
    sha256: await CoffeeV2Checksum.sha256OfFile(path),
    sizeBytes: await File(path).length(),
  );
}
