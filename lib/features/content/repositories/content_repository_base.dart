/// OR-1150 — Generic content repository contract.
library;

import '../shared/models/content_types.dart';
import '../shared/services/content_favorites_store.dart';
import '../shared/services/content_search_service.dart';

abstract class ContentRepository<T extends SearchableContent> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<List<T>> query(ContentQuery query);
  Future<List<T>> getFavorites();
  Future<void> toggleFavorite(String id);
}

abstract class ContentRepositoryBase<T extends SearchableContent>
    implements ContentRepository<T> {
  ContentRepositoryBase({
    required this.searchService,
    required this.favoritesDomain,
    required this.favoritesStore,
  });

  final ContentSearchService<T> searchService;
  final String favoritesDomain;
  final ContentFavoritesStore favoritesStore;

  List<T> get source;

  @override
  Future<List<T>> getAll() async => source;

  @override
  Future<T?> getById(String id) async {
    for (final item in source) {
      if (item.contentId == id) return item;
    }
    return null;
  }

  @override
  Future<List<T>> query(ContentQuery query) async {
    var results = searchService.search(source, query);
    if (query.favoritesOnly) {
      final favs = await favoritesStore.getFavorites(favoritesDomain);
      results = results.where((e) => favs.contains(e.contentId)).toList();
    }
    return results;
  }

  @override
  Future<List<T>> getFavorites() async {
    final favs = await favoritesStore.getFavorites(favoritesDomain);
    return source.where((e) => favs.contains(e.contentId)).toList();
  }

  @override
  Future<void> toggleFavorite(String id) =>
      favoritesStore.toggleFavorite(favoritesDomain, id);
}
