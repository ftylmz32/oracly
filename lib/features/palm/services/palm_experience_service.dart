/// Palm journey — validate, analyze, archive image, versioned reinterpret.
library;

import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_payload.dart';
import '../../../core/reading_version/services/reading_version_service.dart';
import '../../coffee/models/coffee_image_pick.dart';
import '../copy/palm_copy.dart';
import '../data/palm_reading_store.dart';
import '../models/palm_analysis_error.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';
import 'palm_analysis_port.dart';
import 'palm_image_archive.dart';
import 'palm_image_validator.dart';

typedef PalmImagePersister = Future<String> Function({
  required String readingId,
  required String sourcePath,
});

class PalmReinterpretResult {
  const PalmReinterpretResult({
    required this.reading,
    required this.versionAdded,
  });

  final PalmReading reading;
  final bool versionAdded;
}

class PalmExperienceService {
  PalmExperienceService({
    required this._analysis,
    this.store,
    this._versions,
    PalmImagePersister? persistImage,
  }) : _persistImage = persistImage ?? PalmImageArchive.persist;

  final PalmAnalysisPort _analysis;
  final PalmReadingStore? store;
  final ReadingVersionService? _versions;
  final PalmImagePersister _persistImage;

  bool get analysisAvailable => _analysis.isAvailable;

  List<PalmReading> history() => store?.all() ?? const [];

  PalmReading? savedById(String id) => store?.byId(id);

  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    await _ensureValid(image);
    if (!_analysis.isAvailable) {
      throw PalmAnalysisException(
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
      );
    }
    final reading = await _analysis.analyze(image, hand: hand);
    final prior = store?.byId(reading.id);
    final archived = await _persistImage(
      readingId: reading.id,
      sourcePath: image.path,
    );
    final persisted = reading.copyWith(imagePath: archived);
    try {
      await store?.save(persisted);
    } catch (_) {
      await PalmImageArchive.deleteIfOwned(archived);
      rethrow;
    }
    final priorPath = prior?.imagePath;
    if (priorPath != null &&
        priorPath.isNotEmpty &&
        priorPath != archived) {
      await PalmImageArchive.deleteIfOwned(priorPath);
    }
    try {
      await _versions?.seedOriginal(
        rootId: persisted.id,
        kind: ReadingVersionKind.palm,
        data: ReadingVersionPayload.palm(persisted),
      );
    } catch (_) {}
    return persisted;
  }

  /// Resumes an already-staged operation using ONLY the server-held
  /// image — never local bytes. Used to recover a `waiting` operation
  /// after the client's local image state was lost (app restart,
  /// controller disposal). Fails closed (never fabricates a reading)
  /// when the analysis port doesn't support staged resume.
  Future<PalmReading> analyzeStaged({
    required String operationId,
    required String mimeType,
    required PalmHand hand,
  }) async {
    final analysis = _analysis;
    if (analysis is! PalmStagedAnalysisPort) {
      throw PalmAnalysisException(
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
      );
    }
    final staged = analysis as PalmStagedAnalysisPort;
    final reading = await staged.analyzeStaged(
      operationId: operationId,
      mimeType: mimeType,
      hand: hand,
    );
    // No local source to archive — imagePath stays null (already the
    // case on `reading`, per PalmStagedAnalysisPort's contract).
    await store?.save(reading);
    await _versions?.seedOriginal(
      rootId: reading.id,
      kind: ReadingVersionKind.palm,
      data: ReadingVersionPayload.palm(reading),
    );
    return reading;
  }

  Future<PalmReading> restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  }) async {
    final analysis = _analysis;
    if (analysis is! PalmCompletedAnalysisPort) {
      throw PalmAnalysisException(PalmAnalysisError(
        PalmAnalysisErrorKind.unavailable,
        PalmCopy.analysisUnavailable,
      ));
    }
    final reading = (analysis as PalmCompletedAnalysisPort).restoreCompleted(
      resultId: resultId,
      persistedAt: persistedAt,
      hand: hand,
      result: result,
    );
    await store?.save(reading);
    await _versions?.seedOriginal(
      rootId: reading.id,
      kind: ReadingVersionKind.palm,
      data: ReadingVersionPayload.palm(reading),
    );
    return reading;
  }

  Future<PalmReinterpretResult> reinterpret({
    required PalmReading current,
    required CoffeeImagePick image,
    required PalmHand hand,
  }) async {
    await _ensureValid(image);
    if (!_analysis.isAvailable) {
      throw PalmAnalysisException(
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
      );
    }
    final fresh = await _analysis.analyze(image, hand: hand);
    final imagePath = current.imagePath ??
        await _persistImage(
          readingId: current.id,
          sourcePath: image.path,
        );
    final merged = current.copyWith(
      overall: fresh.overall,
      lifeLine: fresh.lifeLine,
      headLine: fresh.headLine,
      heartLine: fresh.heartLine,
      fateLine: fresh.fateLine,
      takeaway: fresh.takeaway,
      symbols: fresh.symbols,
      themes: fresh.themes,
      imagePath: imagePath,
    );
    var added = true;
    final versions = _versions;
    if (versions != null) {
      final result = await versions.tryAppendRevision(
        rootId: current.id,
        kind: ReadingVersionKind.palm,
        data: ReadingVersionPayload.palm(merged),
      );
      added = result.added;
      if (!added) {
        return PalmReinterpretResult(reading: current, versionAdded: false);
      }
    }
    await store?.save(merged);
    return PalmReinterpretResult(reading: merged, versionAdded: added);
  }

  Future<void> _ensureValid(CoffeeImagePick image) async {
    final validation = await PalmImageValidator.validate(image.path);
    if (validation.ok) return;
    final message = validation.message ?? PalmCopy.imageTooSmall;
    final kind = message == PalmCopy.imageMissing
        ? PalmAnalysisErrorKind.missingImage
        : PalmAnalysisErrorKind.unsupportedImage;
    throw PalmAnalysisException(PalmAnalysisError(kind, message));
  }
}
