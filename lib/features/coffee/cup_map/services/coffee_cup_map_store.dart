/// Persists Fincan Haritası records under ONE key, keyed by the coffee
/// reading id. Owner discipline: a record is stamped with the local data
/// owner at creation and only ever returned to (or changed by) that same
/// owner; the key is also cleared by the account-boundary wipe and by the
/// discovery-history clear. Fail closed: if the stored payload cannot be
/// read, nothing is returned and nothing is overwritten.
library;

import 'dart:convert';

import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/data/datasources/local_storage.dart';
import '../../coffee_v3/models/coffee_v3_photo_slot.dart';
import '../models/coffee_cup_map_record.dart';

enum CoffeeCupMapRejection {
  /// No map for this reading and owner.
  notFound,

  /// The photo this pin belongs to is not part of the map.
  noSuchPhoto,

  /// Outside the image (or not a number).
  outOfBounds,

  /// Another pin already marks this place on the same photo.
  samePlace,

  /// The per-photo pin limit is reached.
  limitReached,

  /// The stored payload is unreadable or owned by someone else.
  blocked,
}

class CoffeeCupMapException implements Exception {
  const CoffeeCupMapException(this.reason);
  final CoffeeCupMapRejection reason;

  @override
  String toString() => 'CoffeeCupMapException(${reason.name})';
}

class CoffeeCupMapStore {
  CoffeeCupMapStore(this._storage, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const key = 'coffee_cup_map_v1';

  final LocalStorage _storage;
  final DateTime Function() _clock;
  int _idCounter = 0;

  String get currentOwnerId =>
      _storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';

  /// `null` = nothing stored; throws [FormatException] when unreadable.
  Map<String, CoffeeCupMapRecord>? _readAll() {
    final raw = _storage.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map ||
        decoded['schemaVersion'] != coffeeCupMapSchemaVersion ||
        decoded['maps'] is! Map) {
      throw const FormatException('unsupported_coffee_cup_map');
    }
    final maps = <String, CoffeeCupMapRecord>{};
    for (final entry in (decoded['maps'] as Map).entries) {
      final record = CoffeeCupMapRecord.fromJson(entry.value);
      if (record != null && record.readingId == entry.key) {
        maps[record.readingId] = record;
      }
    }
    return maps;
  }

  Map<String, CoffeeCupMapRecord> _readForWrite() {
    try {
      return _readAll() ?? {};
    } catch (_) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.blocked);
    }
  }

  Future<void> _writeAll(Map<String, CoffeeCupMapRecord> maps) async {
    final ok = await _storage.setString(
      key,
      jsonEncode({
        'schemaVersion': coffeeCupMapSchemaVersion,
        'maps': {
          for (final entry in maps.entries) entry.key: entry.value.toJson(),
        },
      }),
    );
    if (!ok) throw StateError('coffee cup map not persisted');
  }

  /// The current owner's map for [readingId], or `null`.
  CoffeeCupMapRecord? load(String readingId) {
    final owner = currentOwnerId;
    if (owner.isEmpty) return null;
    final Map<String, CoffeeCupMapRecord>? maps;
    try {
      maps = _readAll();
    } catch (_) {
      return null;
    }
    final record = maps?[readingId];
    if (record == null || record.ownerId != owner) return null;
    return record;
  }

  /// Every archived photo path, any owner — the wipe's locator list.
  static List<String> archivedPaths(LocalStorage storage) {
    try {
      final paths = <String>[];
      final records = CoffeeCupMapStore(storage)._readAll()?.values ??
          const <CoffeeCupMapRecord>[];
      for (final record in records) {
        for (final photo in record.photos) {
          paths.add(photo.path);
        }
      }
      return paths;
    } catch (_) {
      return const [];
    }
  }

  /// Creates the map once. An existing map for the reading is never
  /// replaced, so the user's pins can never be wiped by a repeated handoff.
  /// Returns `false` when a map already exists.
  Future<bool> createIfAbsent({
    required String ownerId,
    required String readingId,
    required List<CoffeeCupMapPhoto> photos,
  }) async {
    final owner = currentOwnerId;
    if (owner.isEmpty || owner != ownerId || photos.isEmpty) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.blocked);
    }
    final maps = _readForWrite();
    if (maps.containsKey(readingId)) return false;
    maps[readingId] = CoffeeCupMapRecord(
      ownerId: owner,
      readingId: readingId,
      createdAt: _clock(),
      photos: List.unmodifiable(photos),
    );
    await _writeAll(maps);
    return true;
  }

  CoffeeCupMapRecord _ownedOrThrow(
    Map<String, CoffeeCupMapRecord> maps,
    String readingId,
  ) {
    final owner = currentOwnerId;
    final record = maps[readingId];
    if (owner.isEmpty || record == null || record.ownerId != owner) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.notFound);
    }
    return record;
  }

  Future<CoffeeCupMapRecord> _commit(
    Map<String, CoffeeCupMapRecord> maps,
    CoffeeCupMapRecord next,
  ) async {
    maps[next.readingId] = next;
    await _writeAll(maps);
    return next;
  }

  Future<CoffeeCupMapRecord> addPin({
    required String readingId,
    required CoffeeV3PhotoSlot slot,
    required double x,
    required double y,
    String? note,
  }) async {
    final maps = _readForWrite();
    final record = _ownedOrThrow(maps, readingId);
    if (record.photoFor(slot) == null) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.noSuchPhoto);
    }
    if (!isCoffeeCupMapCoordinate(x) || !isCoffeeCupMapCoordinate(y)) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.outOfBounds);
    }
    final onPhoto = record.pinsFor(slot);
    if (onPhoto.any((p) => p.isSamePlace(slot, x, y))) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.samePlace);
    }
    if (onPhoto.length >= CoffeeCupMapLimits.maxPinsPerPhoto) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.limitReached);
    }
    final now = _clock();
    final pin = CoffeeCupMapPin(
      id: 'pin_${now.microsecondsSinceEpoch}_${_idCounter++}',
      slot: slot,
      x: x,
      y: y,
      createdAt: now,
      note: normalizeCoffeeCupMapNote(note),
    );
    return _commit(maps, record.withPins([...record.pins, pin]));
  }

  Future<CoffeeCupMapRecord> setNote({
    required String readingId,
    required String pinId,
    String? note,
  }) async {
    final maps = _readForWrite();
    final record = _ownedOrThrow(maps, readingId);
    if (!record.pins.any((p) => p.id == pinId)) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.notFound);
    }
    return _commit(
      maps,
      record.withPins([
        for (final pin in record.pins)
          if (pin.id == pinId) pin.withNote(note) else pin,
      ]),
    );
  }

  Future<CoffeeCupMapRecord> removePin({
    required String readingId,
    required String pinId,
  }) async {
    final maps = _readForWrite();
    final record = _ownedOrThrow(maps, readingId);
    return _commit(
      maps,
      record.withPins([
        for (final pin in record.pins)
          if (pin.id != pinId) pin,
      ]),
    );
  }
}
