/// OR-1150 — Oracle message content repository.
library;

import '../../repositories/content_repository_base.dart';
import '../../shared/services/content_search_service.dart';
import '../data/oracle_content_catalogue.dart';
import '../models/oracle_message_content.dart';

abstract class OracleContentRepository extends ContentRepository<OracleMessageContent> {
  Future<OracleMessageContent> getByTheme(OracleMessageTheme theme);
}

class MockOracleContentRepository extends ContentRepositoryBase<OracleMessageContent>
    implements OracleContentRepository {
  MockOracleContentRepository({required super.favoritesStore})
      : super(
          searchService: DefaultContentSearchService<OracleMessageContent>(),
          favoritesDomain: 'oracle',
        );

  @override
  List<OracleMessageContent> get source => OracleContentCatalogue.all;

  @override
  Future<OracleMessageContent> getByTheme(OracleMessageTheme theme) async =>
      OracleContentCatalogue.randomByTheme(theme);
}
