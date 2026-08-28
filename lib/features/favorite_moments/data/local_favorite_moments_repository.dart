/// Persists favorite moments — user-curated only.

library;



import 'dart:convert';



import '../../../core/data/datasources/local_storage.dart';

import '../models/favorite_moment.dart';



class LocalFavoriteMomentsRepository {

  LocalFavoriteMomentsRepository(this._storage);



  final LocalStorage _storage;

  static const key = 'or_favorite_moments_v1';
  static const _key = key;



  Future<List<FavoriteMoment>> getAll() async {

    final raw = _storage.getStringList(_key) ?? const [];

    final items = <FavoriteMoment>[];

    for (final entry in raw) {

      try {

        final decoded = jsonDecode(entry);

        if (decoded is! Map) continue;

        items.add(FavoriteMoment.fromJson(Map<String, dynamic>.from(decoded)));

      } catch (_) {}

    }

    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));

    return items;

  }



  Future<void> save(FavoriteMoment moment) async {

    final current = await getAll();

    final next = [

      moment,

      for (final item in current)

        if (item.id != moment.id) item,

    ];

    await _write(next);

  }



  Future<void> remove(String id) async {

    final current = await getAll();

    await _write([for (final item in current) if (item.id != id) item]);

  }



  Future<bool> contains(String id) async {

    final current = await getAll();

    return current.any((item) => item.id == id);

  }

  Future<void> clearAll() async {
    await _storage.remove(_key);
  }

  Future<void> _write(List<FavoriteMoment> items) async {

    await _storage.setStringList(

      _key,

      [for (final item in items) jsonEncode(item.toJson())],

    );

  }

}


