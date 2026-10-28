/// Persists Fincan Haritası records — photo paths and checksums, the user's
/// pins and notes — as ONE file, `maps_v1.json`, in the durable,
/// backup-excluded [CoffeeCupMapLocation] next to the photos (never in
/// SharedPreferences, which device backups include). Keyed by the coffee
/// reading id.
///
/// Owner discipline: a record is stamped with the local data owner at
/// creation and only ever returned to (or changed by) that same owner.
/// Fail closed: an unreadable file is never shown and never overwritten.
/// Writes are atomic (temp file → backup exclusion verified → rename) and
/// serialized in this process.
///
/// Records written by `2e85526d` (SharedPreferences key + photos in the
/// evictable cache) are migrated on first use; a failed migration keeps the
/// old data untouched and is retried next time.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/auth/user_local_data_isolation.dart';
import '../../../../core/data/datasources/local_storage.dart';
import '../../coffee_v2/services/coffee_v2_checksum.dart';
import '../../coffee_v3/models/coffee_v3_photo_slot.dart';
import '../../../privacy/services/archive_path_kind.dart';
import '../models/coffee_cup_map_record.dart';
import 'coffee_cup_map_location.dart';
import 'coffee_cup_map_photo_archive.dart';

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

  /// The stored file is unreadable, cannot be kept out of backups, or this
  /// platform has no cup-map storage.
  blocked,
}

class CoffeeCupMapException implements Exception {
  const CoffeeCupMapException(this.reason);
  final CoffeeCupMapRejection reason;

  @override
  String toString() => 'CoffeeCupMapException(${reason.name})';
}

class CoffeeCupMapStore {
  CoffeeCupMapStore(
    this._storage, {
    this._location,
    DateTime Function()? clock,
    Future<bool> Function(String path)? deletePhoto,
  })  : _clock = clock ?? DateTime.now,
        _deletePhoto = deletePhoto ?? CoffeeCupMapPhotoArchive.deleteStrict;

  static const fileName = 'maps_v1.json';

  /// Where `2e85526d` kept the records; read only to migrate, then removed.
  static const legacyKey = 'coffee_cup_map_v1';

  final LocalStorage _storage;
  final CoffeeCupMapLocation? _location;
  final DateTime Function() _clock;
  final Future<bool> Function(String path) _deletePhoto;
  int _idCounter = 0;

  /// One writer at a time in this process. Each waiter parks on a completer
  /// made in its own zone, so the lock never depends on an old future.
  static bool _busy = false;
  static final List<Completer<void>> _waiters = [];

  CoffeeCupMapLocation get _where => _location ?? CoffeeCupMapLocation.instance;

  String get currentOwnerId =>
      _storage.getString(UserLocalDataIsolation.ownerKey)?.trim() ?? '';

  Future<T> _serial<T>(Future<T> Function() action) async {
    if (_busy) {
      final turn = Completer<void>();
      _waiters.add(turn);
      await turn.future;
    }
    _busy = true;
    try {
      return await action();
    } finally {
      // Hand the lock straight to the next waiter, or release it.
      if (_waiters.isEmpty) {
        _busy = false;
      } else {
        _waiters.removeAt(0).complete();
      }
    }
  }

  Future<File> _file() async {
    final dir = await _where.directory();
    return File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  static Map<String, CoffeeCupMapRecord> _decode(String raw) {
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

  static String _encode(Map<String, CoffeeCupMapRecord> maps) => jsonEncode({
        'schemaVersion': coffeeCupMapSchemaVersion,
        'maps': {
          for (final entry in maps.entries) entry.key: entry.value.toJson(),
        },
      });

  /// `null` = nothing stored; throws when unreadable or unreachable.
  Future<Map<String, CoffeeCupMapRecord>?> _readAll() async {
    final file = await _file();
    if (!file.existsSync()) return null;
    return _decode(file.readAsStringSync());
  }

  Future<Map<String, CoffeeCupMapRecord>> _readForWrite() async {
    try {
      return await _readAll() ?? {};
    } catch (_) {
      throw const CoffeeCupMapException(CoffeeCupMapRejection.blocked);
    }
  }

  /// Temp file → excluded from backups and confirmed → atomic rename →
  /// exclusion re-applied to the replaced file. Nothing is replaced unless
  /// the new content is confirmed excluded.
  Future<void> _writeAll(Map<String, CoffeeCupMapRecord> maps) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    tmp.writeAsStringSync(_encode(maps), flush: true);
    final excluded = await _where.excludeFromBackup(tmp.path) &&
        await _where.isExcludedFromBackup(tmp.path);
    if (!excluded) {
      if (tmp.existsSync()) tmp.deleteSync();
      throw const CoffeeCupMapException(CoffeeCupMapRejection.blocked);
    }
    tmp.renameSync(file.path);
    await _where.excludeFromBackup(file.path);
  }

  /// The current owner's map for [readingId], or `null` (also when this
  /// platform has no storage or the file is unreadable).
  Future<CoffeeCupMapRecord?> load(String readingId) async {
    final owner = currentOwnerId;
    if (owner.isEmpty) return null;
    try {
      if (_storage.getString(legacyKey) != null) {
        await _serial(_migrateLegacy);
      }
      final record = (await _readAll())?[readingId];
      if (record == null || record.ownerId != owner) return null;
      return record;
    } catch (_) {
      return null;
    }
  }

  /// Every photo path in the map file, any owner — a wipe's locator list.
  static Future<List<String>> archivedPaths(
    LocalStorage storage, {
    CoffeeCupMapLocation? location,
  }) async {
    try {
      final records =
          await CoffeeCupMapStore(storage, location: location)._readAll();
      return [
        for (final record in records?.values ?? const <CoffeeCupMapRecord>[])
          for (final photo in record.photos) photo.path,
      ];
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
  }) =>
      _serial(() async {
        await _migrateLegacy();
        final owner = currentOwnerId;
        if (owner.isEmpty || owner != ownerId || photos.isEmpty) {
          throw const CoffeeCupMapException(CoffeeCupMapRejection.blocked);
        }
        final maps = await _readForWrite();
        if (maps.containsKey(readingId)) return false;
        maps[readingId] = CoffeeCupMapRecord(
          ownerId: owner,
          readingId: readingId,
          createdAt: _clock(),
          photos: List.unmodifiable(photos),
        );
        await _writeAll(maps);
        return true;
      });

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

  Future<CoffeeCupMapRecord> _change(
    String readingId,
    CoffeeCupMapRecord Function(CoffeeCupMapRecord record) change,
  ) =>
      _serial(() async {
        await _migrateLegacy();
        final maps = await _readForWrite();
        final next = change(_ownedOrThrow(maps, readingId));
        maps[readingId] = next;
        await _writeAll(maps);
        return next;
      });

  Future<CoffeeCupMapRecord> addPin({
    required String readingId,
    required CoffeeV3PhotoSlot slot,
    required double x,
    required double y,
    String? note,
  }) =>
      _change(readingId, (record) {
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
          throw const CoffeeCupMapException(
            CoffeeCupMapRejection.limitReached,
          );
        }
        final now = _clock();
        return record.withPins([
          ...record.pins,
          CoffeeCupMapPin(
            id: 'pin_${now.microsecondsSinceEpoch}_${_idCounter++}',
            slot: slot,
            x: x,
            y: y,
            createdAt: now,
            note: normalizeCoffeeCupMapNote(note),
          ),
        ]);
      });

  Future<CoffeeCupMapRecord> setNote({
    required String readingId,
    required String pinId,
    String? note,
  }) =>
      _change(readingId, (record) {
        if (!record.pins.any((p) => p.id == pinId)) {
          throw const CoffeeCupMapException(CoffeeCupMapRejection.notFound);
        }
        return record.withPins([
          for (final pin in record.pins)
            if (pin.id == pinId) pin.withNote(note) else pin,
        ]);
      });

  Future<CoffeeCupMapRecord> removePin({
    required String readingId,
    required String pinId,
  }) =>
      _change(readingId, (record) => record.withPins([
            for (final pin in record.pins)
              if (pin.id != pinId) pin,
          ]));

  /// Deletes this owner's map for [readingId] — its photo files first, then
  /// the record with every pin and note. If any file cannot be removed the
  /// record stays as the locator and this throws; the reading itself is
  /// never touched.
  Future<void> deleteMap(String readingId) => _serial(() async {
        await _migrateLegacy();
        final maps = await _readForWrite();
        final record = _ownedOrThrow(maps, readingId);
        var allGone = true;
        for (final photo in record.photos) {
          if (!await _deletePhoto(photo.path)) allGone = false;
        }
        if (!allGone) throw StateError('coffee cup map photos not deleted');
        maps.remove(readingId);
        await _writeAll(maps);
      });

  /// Account / history wipes: every kept photo and the map file in the
  /// durable location, the pre-migration cache directory and record.
  /// `true` only when all of it is proven gone.
  static Future<bool> purgeStrict(LocalStorage storage) async {
    final durable = await CoffeeCupMapPhotoArchive.purgeStrict();
    final legacyFiles = await CoffeeCupMapLegacyCache.purgeStrict();
    var legacyRecord = true;
    if (legacyFiles && storage.getString(legacyKey) != null) {
      legacyRecord = await storage.remove(legacyKey);
    }
    return durable && legacyFiles && legacyRecord;
  }

  /// Moves `2e85526d` records into the durable file: each still-present
  /// cache photo is copied, excluded from backups and checked against its
  /// recorded SHA-256; photos already evicted keep their old path (shown as
  /// missing, pins kept). Only after the new file is written are the old
  /// record and cache files removed. Any failure removes this run's copies
  /// and leaves the old data exactly as it was, to retry next time.
  Future<void> _migrateLegacy() async {
    final raw = _storage.getString(legacyKey);
    if (raw == null) return;
    final Map<String, CoffeeCupMapRecord> legacy;
    try {
      legacy = _decode(raw);
    } catch (_) {
      return;
    }
    final copies = <String>[];
    final moved = <String>[];
    try {
      final maps = await _readForWrite();
      for (final record in legacy.values) {
        if (maps.containsKey(record.readingId)) continue;
        final photos = <CoffeeCupMapPhoto>[];
        for (final photo in record.photos) {
          final old = File(photo.path);
          final cached =
              await CoffeeCupMapLegacyCache.classify(photo.path) ==
                  ArchivePathKind.owned;
          if (!cached || !old.existsSync()) {
            photos.add(photo);
            continue;
          }
          final copy = await CoffeeCupMapPhotoArchive.persist(
            readingId: '${record.readingId}_cupmap_${photo.slot.wireValue}',
            sourcePath: photo.path,
          );
          copies.add(copy);
          if (await CoffeeV2Checksum.sha256OfFile(copy) != photo.sha256) {
            throw StateError('cup map migration checksum mismatch');
          }
          photos.add(photo.withPath(copy));
          moved.add(photo.path);
        }
        maps[record.readingId] = CoffeeCupMapRecord(
          ownerId: record.ownerId,
          readingId: record.readingId,
          createdAt: record.createdAt,
          photos: List.unmodifiable(photos),
          pins: record.pins,
        );
      }
      await _writeAll(maps);
    } catch (_) {
      for (final copy in copies) {
        try {
          final file = File(copy);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
      return;
    }
    await _storage.remove(legacyKey);
    for (final path in moved) {
      try {
        File(path).deleteSync();
      } catch (_) {
        // Left in the evictable cache; the wipes purge it.
      }
    }
  }
}
