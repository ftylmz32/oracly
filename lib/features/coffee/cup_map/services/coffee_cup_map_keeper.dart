/// Keeps the exact photos a Coffee V3 reading was made from — only when this
/// owner has turned on "keep my photos" — at the one moment their link to
/// that reading is certain: the V3 submission that created the operation
/// has just restored the operation's own result. The photos are re-verified
/// against the checksums recorded at capture and copied into the durable,
/// backup-excluded cup-map archive BEFORE V3 releases its working copies.
///
/// Best effort by contract — no consent or any failure leaves the reading
/// without a map and never touches the reading itself.
library;

import 'dart:io';

import '../../../../core/data/datasources/local_storage.dart';
import '../../coffee_v2/services/coffee_v2_checksum.dart';
import '../../coffee_v3/models/coffee_v3_photo_asset.dart';
import '../../coffee_v3/models/coffee_v3_photo_slot.dart';
import '../../coffee_v3/services/coffee_v3_work_files.dart';
import '../../services/coffee_experience_service.dart' show CoffeeImagePersister;
import '../models/coffee_cup_map_record.dart';
import 'coffee_cup_map_consent.dart';
import 'coffee_cup_map_photo_archive.dart';
import 'coffee_cup_map_store.dart';

typedef CoffeeCupMapAssetCheck = Future<bool> Function(CoffeeV3PhotoAsset);

class CoffeeCupMapKeeper {
  CoffeeCupMapKeeper(
    LocalStorage storage, {
    CoffeeImagePersister? persist,
    CoffeeCupMapAssetCheck? verify,
    Future<bool> Function(String path)? discard,
  })  : _store = CoffeeCupMapStore(storage),
        _consent = CoffeeCupMapConsent(storage),
        _persist = persist ?? CoffeeCupMapPhotoArchive.persist,
        _verify = verify ?? _assetUnchanged,
        _discard = discard ?? CoffeeCupMapPhotoArchive.deleteStrict;

  final CoffeeCupMapStore _store;
  final CoffeeCupMapConsent _consent;
  final CoffeeImagePersister _persist;
  final CoffeeCupMapAssetCheck _verify;
  final Future<bool> Function(String path) _discard;

  /// [submissionOwnerId] is the owner the V3 submission was stamped with;
  /// a map is only kept when it is still the local data owner and that
  /// owner has chosen to keep photos.
  Future<void> keep({
    required String resultId,
    required String? submissionOwnerId,
    required List<CoffeeV3PhotoAsset> assets,
  }) async {
    if (!_consent.keepPhotos) return;
    final owner = _store.currentOwnerId;
    if (owner.isEmpty || submissionOwnerId != owner || assets.isEmpty) return;
    if (await _store.load(resultId) != null) return;

    final kept = <CoffeeCupMapPhoto>[];
    for (final slot in coffeeV3CanonicalSlotOrder) {
      final asset = _assetFor(assets, slot);
      if (asset == null) continue;
      try {
        if (!await _verify(asset)) continue;
        final path = await _persist(
          readingId: '${resultId}_cupmap_${slot.wireValue}',
          sourcePath: asset.path,
        );
        kept.add(
          CoffeeCupMapPhoto(slot: slot, path: path, sha256: asset.sha256),
        );
      } catch (_) {
        // This photo is simply not on the map.
      }
    }
    if (kept.isEmpty) return;

    var created = false;
    try {
      created = await _store.createIfAbsent(
        ownerId: owner,
        readingId: resultId,
        photos: kept,
      );
    } catch (_) {
      created = false;
    }
    if (!created) await _release(kept);
  }

  static CoffeeV3PhotoAsset? _assetFor(
    List<CoffeeV3PhotoAsset> assets,
    CoffeeV3PhotoSlot slot,
  ) {
    for (final asset in assets) {
      if (asset.slot == slot) return asset;
    }
    return null;
  }

  /// A copy that cannot be removed now stays only inside the cup-map
  /// archive, which every account / history wipe purges whole.
  Future<void> _release(List<CoffeeCupMapPhoto> photos) async {
    for (final photo in photos) {
      await _discard(photo.path);
    }
  }

  /// The same trust rule V3 applies to its own draft: only an app-owned V3
  /// working copy whose size and checksum still match what was captured.
  static Future<bool> _assetUnchanged(CoffeeV3PhotoAsset asset) async {
    if (!await CoffeeV3WorkFiles.isOwned(asset.path)) return false;
    final file = File(asset.path);
    if (!await file.exists()) return false;
    if (await file.length() != asset.sizeBytes) return false;
    return await CoffeeV2Checksum.sha256OfFile(asset.path) == asset.sha256;
  }
}
