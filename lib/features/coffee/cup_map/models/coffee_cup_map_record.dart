/// Fincan Haritası — the user's OWN marks on the exact photos one Coffee V3
/// reading was made from. Metadata only (owned archive paths, normalized
/// coordinates, the user's notes); never image bytes, never anything the
/// model detected. A pin is a place the user chose; ORACLY never infers,
/// labels or moves one.
///
/// Coordinates are fractions of the archived image as displayed (the V3
/// normalizer bakes EXIF orientation into the pixels and drops EXIF, so the
/// same file always renders the same way): `x` 0 = left edge, 1 = right;
/// `y` 0 = top, 1 = bottom.
library;

import '../../coffee_v3/models/coffee_v3_photo_slot.dart';

/// The only cup-map schema this client reads or writes.
const int coffeeCupMapSchemaVersion = 1;

abstract final class CoffeeCupMapLimits {
  CoffeeCupMapLimits._();

  static const int maxPinsPerPhoto = 12;
  static const int maxNoteLength = 240;

  /// Two pins closer than this (in normalized units) on the same photo are
  /// the same place — a tap there selects the existing pin instead.
  static const double samePlaceRadius = 0.04;
}

class CoffeeCupMapPhoto {
  const CoffeeCupMapPhoto({
    required this.slot,
    required this.path,
    required this.sha256,
  });

  final CoffeeV3PhotoSlot slot;

  /// App-owned `coffee_images` archive copy — never the camera original.
  final String path;

  /// Checksum of the photo that was staged for this reading.
  final String sha256;

  CoffeeCupMapPhoto withPath(String next) =>
      CoffeeCupMapPhoto(slot: slot, path: next, sha256: sha256);

  Map<String, dynamic> toJson() => {
        'slot': slot.wireValue,
        'path': path,
        'sha256': sha256,
      };

  static CoffeeCupMapPhoto? fromJson(Object? json) {
    if (json is! Map) return null;
    final slot = coffeeV3PhotoSlotFromWire(json['slot'] as String?);
    final path = json['path'];
    final sha256 = json['sha256'];
    if (slot == null) return null;
    if (path is! String || path.trim().isEmpty) return null;
    if (sha256 is! String || sha256.isEmpty) return null;
    return CoffeeCupMapPhoto(slot: slot, path: path, sha256: sha256);
  }
}

class CoffeeCupMapPin {
  const CoffeeCupMapPin({
    required this.id,
    required this.slot,
    required this.x,
    required this.y,
    required this.createdAt,
    this.note,
  });

  final String id;
  final CoffeeV3PhotoSlot slot;
  final double x;
  final double y;
  final String? note;
  final DateTime createdAt;

  bool get hasNote => note != null && note!.isNotEmpty;

  CoffeeCupMapPin withNote(String? next) => CoffeeCupMapPin(
        id: id,
        slot: slot,
        x: x,
        y: y,
        createdAt: createdAt,
        note: normalizeCoffeeCupMapNote(next),
      );

  bool isSamePlace(CoffeeV3PhotoSlot otherSlot, double ox, double oy) {
    if (otherSlot != slot) return false;
    final dx = ox - x;
    final dy = oy - y;
    return dx * dx + dy * dy <
        CoffeeCupMapLimits.samePlaceRadius * CoffeeCupMapLimits.samePlaceRadius;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slot': slot.wireValue,
        'x': x,
        'y': y,
        if (hasNote) 'note': note,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static CoffeeCupMapPin? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final slot = coffeeV3PhotoSlotFromWire(json['slot'] as String?);
    final x = json['x'];
    final y = json['y'];
    final created = DateTime.tryParse('${json['createdAt']}');
    if (id is! String || id.isEmpty || slot == null || created == null) {
      return null;
    }
    if (x is! num || y is! num) return null;
    if (!isCoffeeCupMapCoordinate(x) || !isCoffeeCupMapCoordinate(y)) {
      return null;
    }
    final note = json['note'];
    return CoffeeCupMapPin(
      id: id,
      slot: slot,
      x: x.toDouble(),
      y: y.toDouble(),
      createdAt: created,
      note: note is String ? normalizeCoffeeCupMapNote(note) : null,
    );
  }
}

class CoffeeCupMapRecord {
  const CoffeeCupMapRecord({
    required this.ownerId,
    required this.readingId,
    required this.createdAt,
    required this.photos,
    this.pins = const [],
  });

  final String ownerId;
  final String readingId;
  final DateTime createdAt;
  final List<CoffeeCupMapPhoto> photos;
  final List<CoffeeCupMapPin> pins;

  CoffeeCupMapPhoto? photoFor(CoffeeV3PhotoSlot slot) {
    for (final photo in photos) {
      if (photo.slot == slot) return photo;
    }
    return null;
  }

  List<CoffeeCupMapPin> pinsFor(CoffeeV3PhotoSlot slot) =>
      [for (final pin in pins) if (pin.slot == slot) pin];

  CoffeeCupMapRecord withPins(List<CoffeeCupMapPin> next) => CoffeeCupMapRecord(
        ownerId: ownerId,
        readingId: readingId,
        createdAt: createdAt,
        photos: photos,
        pins: List.unmodifiable(next),
      );

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'readingId': readingId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'photos': [for (final p in photos) p.toJson()],
        'pins': [for (final p in pins) p.toJson()],
      };

  /// Unreadable pieces are dropped, never guessed: a photo filed twice for
  /// one slot keeps only the first, a pin for a slot with no photo is
  /// dropped, and so is a pin past the per-photo limit.
  static CoffeeCupMapRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final ownerId = json['ownerId'];
    final readingId = json['readingId'];
    final created = DateTime.tryParse('${json['createdAt']}');
    if (ownerId is! String || ownerId.isEmpty) return null;
    if (readingId is! String || readingId.isEmpty) return null;
    if (created == null) return null;
    final photos = <CoffeeCupMapPhoto>[];
    final rawPhotos = json['photos'];
    if (rawPhotos is List) {
      for (final raw in rawPhotos) {
        final photo = CoffeeCupMapPhoto.fromJson(raw);
        if (photo == null) continue;
        if (photos.any((p) => p.slot == photo.slot)) continue;
        photos.add(photo);
      }
    }
    if (photos.isEmpty) return null;
    final pins = <CoffeeCupMapPin>[];
    final rawPins = json['pins'];
    if (rawPins is List) {
      for (final raw in rawPins) {
        final pin = CoffeeCupMapPin.fromJson(raw);
        if (pin == null) continue;
        if (!photos.any((p) => p.slot == pin.slot)) continue;
        if (pins.any((p) => p.id == pin.id)) continue;
        if (pins.where((p) => p.slot == pin.slot).length >=
            CoffeeCupMapLimits.maxPinsPerPhoto) {
          continue;
        }
        pins.add(pin);
      }
    }
    return CoffeeCupMapRecord(
      ownerId: ownerId,
      readingId: readingId,
      createdAt: created,
      photos: List.unmodifiable(photos),
      pins: List.unmodifiable(pins),
    );
  }
}

bool isCoffeeCupMapCoordinate(num value) =>
    value.isFinite && value >= 0 && value <= 1;

/// Trimmed, length-capped; an empty note is no note.
String? normalizeCoffeeCupMapNote(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.length > CoffeeCupMapLimits.maxNoteLength
      ? trimmed.substring(0, CoffeeCupMapLimits.maxNoteLength)
      : trimmed;
}
