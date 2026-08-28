/// Coffee journey: validate photo, analyze if a real source exists, persist.
library;

import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_payload.dart';
import '../../../core/reading_version/services/reading_version_service.dart';
import '../copy/coffee_copy.dart';
import '../data/coffee_reading_store.dart';
import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';
import 'coffee_analysis_port.dart';
import 'coffee_image_validator.dart';

class CoffeeReinterpretResult {
  const CoffeeReinterpretResult({
    required this.reading,
    required this.versionAdded,
  });

  final CoffeeReading reading;
  final bool versionAdded;
}

class CoffeeExperienceService {
  CoffeeExperienceService({
    required this._store,
    required this._analysis,
    ReadingVersionService? versions,
  }) : _versions = versions;

  final CoffeeReadingStore _store;
  final CoffeeAnalysisPort _analysis;
  final ReadingVersionService? _versions;

  bool get analysisAvailable => _analysis.isAvailable;

  List<CoffeeReading> history() => _store.all();

  CoffeeReading? savedById(String id) => _store.byId(id);

  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    final validation = await CoffeeImageValidator.validate(image.path);
    if (!validation.ok) {
      throw CoffeeAnalysisException(
        validation.message ?? CoffeeCopy.imageUnclear,
      );
    }
    if (!_analysis.isAvailable) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final reading = await _analysis.analyze(image);
    await _store.save(reading);
    await _versions?.seedOriginal(
      rootId: reading.id,
      kind: ReadingVersionKind.coffee,
      data: ReadingVersionPayload.coffee(reading),
    );
    return reading;
  }

  Future<CoffeeReinterpretResult> reinterpret({
    required CoffeeReading current,
    required CoffeeImagePick image,
  }) async {
    final validation = await CoffeeImageValidator.validate(image.path);
    if (!validation.ok) {
      throw CoffeeAnalysisException(
        validation.message ?? CoffeeCopy.imageUnclear,
      );
    }
    if (!_analysis.isAvailable) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final fresh = await _analysis.analyze(image);
    final merged = CoffeeReading(
      id: current.id,
      createdAt: current.createdAt,
      imagePath: current.imagePath ?? fresh.imagePath,
      overall: fresh.overall,
      love: fresh.love,
      career: fresh.career,
      money: fresh.money,
      nearFuture: fresh.nearFuture,
      takeaway: fresh.takeaway,
      visualObservation: fresh.visualObservation,
      symbols: fresh.symbols,
    );
    final payload = ReadingVersionPayload.coffee(merged);
    var added = true;
    final versions = _versions;
    if (versions != null) {
      final result = await versions.tryAppendRevision(
        rootId: current.id,
        kind: ReadingVersionKind.coffee,
        data: payload,
      );
      added = result.added;
      if (!added) return CoffeeReinterpretResult(reading: current, versionAdded: false);
    }
    await _store.save(merged);
    return CoffeeReinterpretResult(reading: merged, versionAdded: added);
  }
}
