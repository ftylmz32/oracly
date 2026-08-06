/// OR-1150 — Daily energy content repository.
library;

import '../../repositories/content_repository_base.dart';
import '../../shared/services/content_search_service.dart';
import '../data/daily_energy_content_catalogue.dart';
import '../models/daily_energy_content.dart';

abstract class DailyEnergyContentRepository
    extends ContentRepository<DailyEnergyContent> {
  Future<DailyEnergyContent> getForDate(DateTime date);
}

class MockDailyEnergyContentRepository
    extends ContentRepositoryBase<DailyEnergyContent>
    implements DailyEnergyContentRepository {
  MockDailyEnergyContentRepository({required super.favoritesStore})
      : super(
          searchService: DefaultContentSearchService<DailyEnergyContent>(),
          favoritesDomain: 'daily_energy',
        );

  @override
  List<DailyEnergyContent> get source => [
        DailyEnergyContentCatalogue.forDate(DateTime.now()),
      ];

  @override
  Future<DailyEnergyContent> getForDate(DateTime date) async =>
      DailyEnergyContentCatalogue.forDate(date);
}
