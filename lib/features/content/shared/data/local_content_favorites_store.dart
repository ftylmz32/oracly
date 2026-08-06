/// OR-1150 — Local favorites via SharedPreferences abstraction.
library;

import '../../../../core/data/datasources/local_storage.dart';
import '../services/content_favorites_store.dart';

class LocalContentFavoritesStore implements ContentFavoritesStore {
  LocalContentFavoritesStore(this._storage);

  final LocalStorage _storage;

  String _key(String domain) => 'content_favorites_$domain';

  @override
  Future<Set<String>> getFavorites(String domain) async {
    final list = _storage.getStringList(_key(domain));
    return list?.toSet() ?? {};
  }

  @override
  Future<bool> isFavorite(String domain, String contentId) async {
    final set = await getFavorites(domain);
    return set.contains(contentId);
  }

  @override
  Future<void> toggleFavorite(String domain, String contentId) async {
    final set = await getFavorites(domain);
    if (set.contains(contentId)) {
      await removeFavorite(domain, contentId);
    } else {
      await addFavorite(domain, contentId);
    }
  }

  @override
  Future<void> addFavorite(String domain, String contentId) async {
    final set = await getFavorites(domain);
    await _storage.setStringList(_key(domain), [...set, contentId].toList());
  }

  @override
  Future<void> removeFavorite(String domain, String contentId) async {
    final set = await getFavorites(domain);
    set.remove(contentId);
    await _storage.setStringList(_key(domain), set.toList());
  }
}
