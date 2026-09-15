/// A normalized, confirmed-eligible Coffee V2 source photo. Deliberately
/// holds only a local file reference and metadata — never image bytes,
/// never base64, never a decoded `ui.Image`. Three of these may coexist as
/// persistent state; their byte arrays never do.
library;

import 'coffee_v2_photo_slot.dart';

class CoffeeV2PhotoAsset {
  const CoffeeV2PhotoAsset({
    required this.slot,
    required this.path,
    required this.mimeType,
    required this.sha256,
    required this.sizeBytes,
  });

  final CoffeeV2PhotoSlot slot;
  final String path;
  final String mimeType;
  final String sha256;
  final int sizeBytes;

  CoffeeV2PhotoAsset copyWith({
    CoffeeV2PhotoSlot? slot,
    String? path,
    String? mimeType,
    String? sha256,
    int? sizeBytes,
  }) {
    return CoffeeV2PhotoAsset(
      slot: slot ?? this.slot,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      sha256: sha256 ?? this.sha256,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot.wireValue,
        'path': path,
        'mimeType': mimeType,
        'sha256': sha256,
        'sizeBytes': sizeBytes,
      };

  static CoffeeV2PhotoAsset? fromJson(Object? json) {
    if (json is! Map) return null;
    final slot = coffeeV2PhotoSlotFromWire(json['slot'] as String?);
    final path = json['path'];
    final mimeType = json['mimeType'];
    final sha256 = json['sha256'];
    final sizeBytes = json['sizeBytes'];
    if (slot == null) return null;
    if (path is! String || path.isEmpty) return null;
    if (mimeType is! String || mimeType.isEmpty) return null;
    if (sha256 is! String || sha256.isEmpty) return null;
    if (sizeBytes is! int) return null;
    return CoffeeV2PhotoAsset(
      slot: slot,
      path: path,
      mimeType: mimeType,
      sha256: sha256,
      sizeBytes: sizeBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoffeeV2PhotoAsset &&
      other.slot == slot &&
      other.path == path &&
      other.mimeType == mimeType &&
      other.sha256 == sha256 &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(slot, path, mimeType, sha256, sizeBytes);
}
