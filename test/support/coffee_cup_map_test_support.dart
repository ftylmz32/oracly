/// Fincan Haritası test fixtures: a path provider that serves BOTH the V3
/// working dir (application support) and the owned `coffee_images` archive
/// (application documents), a real cup photo from the repo, and V3 photo
/// assets built from real files with their real checksums.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_checksum.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_asset.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_work_files.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A real photo of a coffee cup already tracked in the repo.
const cupMapFixturePhoto = 'tool/matrix_evidence/test_coffee_cup.jpg';

class CupMapPaths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  CupMapPaths(this.root);
  final String root;

  String get documents => '$root${Platform.pathSeparator}documents';

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationDocumentsPath() async => documents;

  @override
  Future<String?> getTemporaryPath() async => root;

  @override
  Future<String?> getApplicationCachePath() async => root;
}

Future<CupMapPaths> installCupMapPaths(Directory temp) async {
  final paths = CupMapPaths(temp.path);
  await Directory(paths.documents).create(recursive: true);
  PathProviderPlatform.instance = paths;
  return paths;
}

Future<LocalStorage> ownedStorage(String ownerId) async {
  final storage = LocalStorage.ephemeral();
  await storage.setString(UserLocalDataIsolation.ownerKey, ownerId);
  return storage;
}

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
