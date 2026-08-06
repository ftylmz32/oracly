/// OR-1150 — Favorites persistence contract.
library;

abstract class ContentFavoritesStore {
  Future<Set<String>> getFavorites(String domain);
  Future<bool> isFavorite(String domain, String contentId);
  Future<void> toggleFavorite(String domain, String contentId);
  Future<void> addFavorite(String domain, String contentId);
  Future<void> removeFavorite(String domain, String contentId);
}
