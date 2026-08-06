/// OR-1150 — Dream symbol content repository.
library;

import '../../repositories/content_repository_base.dart';
import '../../shared/services/content_search_service.dart';
import '../data/dream_symbol_catalogue.dart';
import '../models/dream_symbol_content.dart';

abstract class DreamContentRepository extends ContentRepository<DreamSymbolContent> {
  Future<List<DreamSymbolContent>> getByCategory(DreamSymbolCategory category);
}

class MockDreamContentRepository extends ContentRepositoryBase<DreamSymbolContent>
    implements DreamContentRepository {
  MockDreamContentRepository({required super.favoritesStore})
      : super(
          searchService: DefaultContentSearchService<DreamSymbolContent>(),
          favoritesDomain: 'dream',
        );

  @override
  List<DreamSymbolContent> get source => DreamSymbolCatalogue.all;

  @override
  Future<List<DreamSymbolContent>> getByCategory(
    DreamSymbolCategory category,
  ) async =>
      DreamSymbolCatalogue.byCategory(category);
}
