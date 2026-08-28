/// Local version chains — one row per reading root id.

library;



import 'dart:convert';



import '../../data/datasources/local_storage.dart';

import '../models/reading_version_group.dart';



class ReadingVersionStore {

  ReadingVersionStore(this._storage);



  static const key = 'or_reading_versions_v1';



  final LocalStorage _storage;



  ReadingVersionGroup? byRootId(String rootId) {

    final raw = _storage.getString(key);

    if (raw == null || raw.isEmpty) return null;

    try {

      final map = jsonDecode(raw) as Map<String, dynamic>;

      final row = map[rootId];

      if (row is! Map<String, dynamic>) return null;

      return ReadingVersionGroup.fromJson(row);

    } catch (_) {

      return null;

    }

  }



  Future<void> save(ReadingVersionGroup group) async {

    final raw = _storage.getString(key);

    final map = raw == null || raw.isEmpty

        ? <String, dynamic>{}

        : Map<String, dynamic>.from(jsonDecode(raw) as Map);

    map[group.rootId] = group.toJson();

    await _storage.setString(key, jsonEncode(map));

  }

}


