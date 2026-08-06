/// OR-1100 — Settings / personalization service.
library;

import '../../features/premium/models/personalization_models.dart';
import '../domain/repositories/settings_repository.dart';

class SettingsService {
  SettingsService(this._repository);

  final SettingsRepository _repository;

  Future<PersonalizationSettings> load() => _repository.load();

  Future<void> save(PersonalizationSettings settings) =>
      _repository.save(settings);
}
