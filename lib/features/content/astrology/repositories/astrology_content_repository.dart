/// OR-1150 — Astrology content repository.
library;

import '../../shared/models/content_types.dart';
import '../../shared/services/content_favorites_store.dart';
import '../../shared/services/content_search_service.dart';
import '../data/astrology_content_catalogue.dart';
import '../models/astrology_content.dart';

abstract class AstrologyContentRepository {
  Future<List<ZodiacSignContent>> getSigns();
  Future<List<PlanetContent>> getPlanets();
  Future<List<HouseContent>> getHouses();
  Future<List<AspectContent>> getAspects();
  Future<List<CompatibilityContent>> getCompatibility();
  Future<ZodiacSignContent?> getSignById(String id);
  Future<List<ZodiacSignContent>> searchSigns(ContentQuery query);
  Future<void> toggleSignFavorite(String id);
}

class MockAstrologyContentRepository implements AstrologyContentRepository {
  MockAstrologyContentRepository({
    required ContentFavoritesStore favoritesStore,
  })  : _favorites = favoritesStore,
        _search = DefaultContentSearchService<ZodiacSignContent>();

  final ContentFavoritesStore _favorites;
  final ContentSearchService<ZodiacSignContent> _search;

  @override
  Future<List<ZodiacSignContent>> getSigns() async =>
      AstrologyContentCatalogue.signs;

  @override
  Future<List<PlanetContent>> getPlanets() async =>
      AstrologyContentCatalogue.planets;

  @override
  Future<List<HouseContent>> getHouses() async =>
      AstrologyContentCatalogue.houses;

  @override
  Future<List<AspectContent>> getAspects() async =>
      AstrologyContentCatalogue.aspects;

  @override
  Future<List<CompatibilityContent>> getCompatibility() async =>
      AstrologyContentCatalogue.compatibility;

  @override
  Future<ZodiacSignContent?> getSignById(String id) async =>
      AstrologyContentCatalogue.signById(id);

  @override
  Future<List<ZodiacSignContent>> searchSigns(ContentQuery query) async {
    var results = _search.search(AstrologyContentCatalogue.signs, query);
    if (query.favoritesOnly) {
      final favs = await _favorites.getFavorites('astrology');
      results = results.where((e) => favs.contains(e.contentId)).toList();
    }
    return results;
  }

  @override
  Future<void> toggleSignFavorite(String id) =>
      _favorites.toggleFavorite('astrology', id);
}
