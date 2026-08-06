/// OR-1150 — Tarot content repository.
library;

import '../../repositories/content_repository_base.dart';
import '../../shared/cache/content_cache.dart';
import '../../shared/services/content_search_service.dart';
import '../data/tarot_content_catalogue.dart';
import '../models/tarot_card_content.dart';

abstract class TarotContentRepository extends ContentRepository<TarotCardContent> {
  Future<List<TarotCardContent>> getMajorArcana();
  Future<List<TarotCardContent>> getMinorArcana();
  Future<TarotCardContent?> getByNumericId(int id);
}

class MockTarotContentRepository extends ContentRepositoryBase<TarotCardContent>
    implements TarotContentRepository {
  MockTarotContentRepository({
    required super.favoritesStore,
    this.cacheLayer,
  }) : super(
          searchService: DefaultContentSearchService<TarotCardContent>(),
          favoritesDomain: 'tarot',
        );

  final ContentCacheLayer? cacheLayer;
  CachedContentReader<TarotCardContent>? _reader;

  CachedContentReader<TarotCardContent> get _cachedReader => _reader ??=
      CachedContentReader(
        cache: cacheLayer ?? InMemoryContentCache(),
        namespace: 'tarot_content',
        fromJson: TarotCardContent.fromJson,
        toJson: (c) => c.toJson(),
      );

  @override
  List<TarotCardContent> get source => TarotContentCatalogue.all;

  @override
  Future<List<TarotCardContent>> getAll() => cacheLayer != null
      ? _cachedReader.readAll('all', () async => source)
      : super.getAll();

  @override
  Future<TarotCardContent?> getByNumericId(int id) async {
    final card = TarotContentCatalogue.byId(id);
    return card;
  }

  @override
  Future<List<TarotCardContent>> getMajorArcana() async =>
      TarotContentCatalogue.majorArcana;

  @override
  Future<List<TarotCardContent>> getMinorArcana() async =>
      TarotContentCatalogue.minorArcana;
}
