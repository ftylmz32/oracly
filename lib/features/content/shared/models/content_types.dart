/// OR-1150 — Shared content identifiers and enums.
library;

enum ContentDomain {
  tarot,
  dream,
  astrology,
  dailyEnergy,
  oracle,
}

enum ContentRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

enum SortOrder { asc, desc }

class ContentQuery {
  const ContentQuery({
    this.search,
    this.categories = const [],
    this.tags = const [],
    this.favoritesOnly = false,
    this.limit,
    this.offset = 0,
  });

  final String? search;
  final List<String> categories;
  final List<String> tags;
  final bool favoritesOnly;
  final int? limit;
  final int offset;

  ContentQuery copyWith({
    String? search,
    List<String>? categories,
    List<String>? tags,
    bool? favoritesOnly,
    int? limit,
    int? offset,
  }) {
    return ContentQuery(
      search: search ?? this.search,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
