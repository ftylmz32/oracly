/// A normalized Coffee V3 source photo — a local file reference plus
/// metadata only. Never image bytes, base64, a decoded image or any token.
/// Deliberately a small additive copy of the V2 asset model so V2 stays
/// untouched.
library;

import 'coffee_v3_photo_slot.dart';

class CoffeeV3PhotoAsset {
  const CoffeeV3PhotoAsset({
    required this.slot,
    required this.path,
    required this.mimeType,
    required this.sha256,
    required this.sizeBytes,
  });

  final CoffeeV3PhotoSlot slot;
  final String path;
  final String mimeType;
  final String sha256;
  final int sizeBytes;

  Map<String, dynamic> toJson() => {
        'slot': slot.wireValue,
        'path': path,
        'mimeType': mimeType,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
      };

  static CoffeeV3PhotoAsset? fromJson(Object? json) {
    if (json is! Map) return null;
    final slot = coffeeV3PhotoSlotFromWire(json['slot'] as String?);
    final path = json['path'];
    final mimeType = json['mimeType'];
    final sha256 = json['sha256'];
    final sizeBytes = json['sizeBytes'];
    if (slot == null) return null;
    if (path is! String || path.isEmpty) return null;
    if (mimeType is! String || mimeType.isEmpty) return null;
    if (sha256 is! String || sha256.isEmpty) return null;
    if (sizeBytes is! int) return null;
    return CoffeeV3PhotoAsset(
      slot: slot,
      path: path,
      mimeType: mimeType,
      sha256: sha256,
      sizeBytes: sizeBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoffeeV3PhotoAsset &&
      other.slot == slot &&
      other.path == path &&
      other.mimeType == mimeType &&
      other.sha256 == sha256 &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(slot, path, mimeType, sha256, sizeBytes);
}
