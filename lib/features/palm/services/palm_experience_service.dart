/// Palm journey — validate, analyze, archive image, versioned reinterpret.
library;

import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_fingerprint.dart';
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
    // Reading metadata is the commit point — save it durably FIRST.
    await store?.save(reading);
    // Version seed is post-commit enrichment — its failure must never
    // turn an already-durable reading into a user-visible failure.
    try {
      await _versions?.seedOriginal(
        rootId: reading.id,
        kind: ReadingVersionKind.palm,
        data: ReadingVersionPayload.palm(reading),
      );
    } catch (_) {}
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
    // Reading metadata is the commit point — save it durably FIRST.
    await store?.save(reading);
    // Version seed is post-commit enrichment — its failure must never
    // turn an already-durable reading into a user-visible failure.
    try {
      await _versions?.seedOriginal(
        rootId: reading.id,
        kind: ReadingVersionKind.palm,
        data: ReadingVersionPayload.palm(reading),
      );
    } catch (_) {}
    return reading;
  }

  /// Reading metadata is the durable commit point; version history is
  /// secondary enrichment. Order matters: (1) a NON-MUTATING duplicate
  /// check — safe before any commit because the palm fingerprint is
  /// text-only and never depends on `imagePath` — (2) only then create a
  /// new image candidate (never for a duplicate/no-op, so nothing is ever
  /// orphaned by one), (3) durably save the merged reading, rolling back
  /// ONLY a newly-created candidate (never a prior committed image) if
  /// that save fails, and (4) append the version revision best-effort
  /// AFTER the reading itself is durable.
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

    final versions = _versions;
    if (versions != null) {
      final probe = current.copyWith(
        overall: fresh.overall,
        lifeLine: fresh.lifeLine,
        headLine: fresh.headLine,
        heartLine: fresh.heartLine,
        fateLine: fresh.fateLine,
        takeaway: fresh.takeaway,
        symbols: fresh.symbols,
        themes: fresh.themes,
      );
      final probeFingerprint = ReadingVersionFingerprint.of(
        ReadingVersionPayload.palm(probe),
        ReadingVersionKind.palm,
      );
      final activeFingerprint =
          versions.groupFor(current.id)?.activeEntry?.fingerprint;
      if (activeFingerprint == probeFingerprint) {
        return PalmReinterpretResult(reading: current, versionAdded: false);
      }
    }

    final createdCandidate = current.imagePath == null;
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

    try {
      await store?.save(merged);
    } catch (_) {
      if (createdCandidate) await PalmImageArchive.deleteIfOwned(imagePath);
      rethrow;
    }

    var added = false;
    if (versions != null) {
      try {
        final result = await versions.tryAppendRevision(
          rootId: current.id,
          kind: ReadingVersionKind.palm,
          data: ReadingVersionPayload.palm(merged),
        );
        added = result.added;
      } catch (_) {
        // Enrichment failure must not turn the already-durable reading
        // into a user-visible "analysis failed".
      }
    }
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
