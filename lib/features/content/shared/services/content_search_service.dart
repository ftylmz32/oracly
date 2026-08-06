/// OR-1150 — Searchable content contract.
library;

import '../models/content_types.dart';

abstract class SearchableContent {
  String get contentId;
  String get displayName;
  String get searchText;
  List<String> get categories;
  List<String> get tags;
}

abstract class ContentSearchService<T extends SearchableContent> {
  List<T> search(List<T> source, ContentQuery query);
  List<T> filterByCategory(List<T> source, String category);
  List<T> filterByCategories(List<T> source, List<String> categories);
}

class DefaultContentSearchService<T extends SearchableContent>
    implements ContentSearchService<T> {
  @override
  List<T> search(List<T> source, ContentQuery query) {
    Iterable<T> results = source;

    if (query.categories.isNotEmpty) {
      results = filterByCategories(results.toList(), query.categories);
    }

    if (query.tags.isNotEmpty) {
      results = results.where(
        (item) => query.tags.every((tag) => item.tags.contains(tag)),
      );
    }

    final term = query.search?.trim().toLowerCase();
    if (term != null && term.isNotEmpty) {
      results = results.where(
        (item) => item.searchText.toLowerCase().contains(term),
      );
    }

    var list = results.toList();
    if (query.offset > 0) {
      list = list.length > query.offset ? list.sublist(query.offset) : [];
    }
    if (query.limit != null && list.length > query.limit!) {
      list = list.sublist(0, query.limit);
    }
    return list;
  }

  @override
  List<T> filterByCategory(List<T> source, String category) {
    return source.where((e) => e.categories.contains(category)).toList();
  }

  @override
  List<T> filterByCategories(List<T> source, List<String> categories) {
    return source
        .where((e) => categories.any((c) => e.categories.contains(c)))
        .toList();
  }
}
