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
import 'coffee_image_archive.dart';
import 'coffee_image_validator.dart';

typedef CoffeeImagePersister = Future<String> Function({
  required String readingId,
  required String sourcePath,
});

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
    CoffeeImagePersister? persistImage,
  })  : _versions = versions,
        _persistImage = persistImage ?? CoffeeImageArchive.persist;

  final CoffeeReadingStore _store;
  final CoffeeAnalysisPort _analysis;
  final ReadingVersionService? _versions;
  final CoffeeImagePersister _persistImage;

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
    final archived = await _persistImage(
      readingId: reading.id,
      sourcePath: image.path,
    );
    final persisted = CoffeeReading(
      id: reading.id,
      createdAt: reading.createdAt,
      imagePath: archived,
      overall: reading.overall,
      love: reading.love,
      career: reading.career,
      money: reading.money,
      nearFuture: reading.nearFuture,
      takeaway: reading.takeaway,
      visualObservation: reading.visualObservation,
      symbols: reading.symbols,
    );
    await _store.save(persisted);
    await _versions?.seedOriginal(
      rootId: persisted.id,
      kind: ReadingVersionKind.coffee,
      data: ReadingVersionPayload.coffee(persisted),
    );
    return persisted;
  }

  /// Resumes an already-staged operation using ONLY the server-held
  /// image — never local bytes. Used to recover a `waiting` operation
  /// after the client's local image state was lost (app restart,
  /// controller disposal). Fails closed (never fabricates a reading)
  /// when the analysis port doesn't support staged resume.
  Future<CoffeeReading> analyzeStaged({
    required String operationId,
    required String mimeType,
  }) async {
    final analysis = _analysis;
    if (analysis is! CoffeeStagedAnalysisPort) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final staged = analysis as CoffeeStagedAnalysisPort;
    final reading = await staged.analyzeStaged(
      operationId: operationId,
      mimeType: mimeType,
    );
    // No local source to archive — imagePath stays null (already the
    // case on `reading`, per CoffeeStagedAnalysisPort's contract).
    await _store.save(reading);
    await _versions?.seedOriginal(
      rootId: reading.id,
      kind: ReadingVersionKind.coffee,
      data: ReadingVersionPayload.coffee(reading),
    );
    return reading;
  }

  Future<CoffeeReading> restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) async {
    final analysis = _analysis;
    if (analysis is! CoffeeCompletedAnalysisPort) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final reading = (analysis as CoffeeCompletedAnalysisPort).restoreCompleted(
      resultId: resultId,
      persistedAt: persistedAt,
      result: result,
    );
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
    final imagePath = current.imagePath ??
        await _persistImage(
          readingId: current.id,
          sourcePath: image.path,
        );
    final merged = CoffeeReading(
      id: current.id,
      createdAt: current.createdAt,
      imagePath: imagePath,
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
