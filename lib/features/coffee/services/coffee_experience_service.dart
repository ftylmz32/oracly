/// Coffee journey: validate photo, analyze if a real source exists, persist.
library;

import '../../../core/auth/owner_history_scope.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_fingerprint.dart';
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

  ({String ownerId, int epoch}) captureOwner() => (
        ownerId: _store.currentOwnerId,
        epoch: UserLocalDataIsolation.accountSwitchEpoch.value,
      );

  Future<void> _saveOwned(
    CoffeeReading reading,
    ({String ownerId, int epoch}) stamp,
  ) {
    return OwnerHistoryScope.commitBound(
      ownerId: stamp.ownerId,
      epoch: stamp.epoch,
      save: () => _store.save(reading),
    );
  }

  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    final stamp = captureOwner();
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
    final prior = _store.byId(reading.id);
    final archived = await _persistImage(
      readingId: reading.id,
      sourcePath: image.path,
    );
    final persisted = CoffeeReading(
      id: reading.id,
      createdAt: reading.createdAt,
      imagePath: archived,
      coffeeResultContract: reading.coffeeResultContract,
      overall: reading.overall,
      love: reading.love,
      career: reading.career,
      money: reading.money,
      nearFuture: reading.nearFuture,
      takeaway: reading.takeaway,
      visualObservation: reading.visualObservation,
      symbols: reading.symbols,
    );
    try {
      await _saveOwned(persisted, stamp);
    } catch (_) {
      if (!await CoffeeImageArchive.deleteIfOwnedStrict(archived)) {
        await _store.journalOwnedImagePath(archived);
      }
      rethrow;
    }
    final priorPath = prior?.imagePath;
    if (priorPath != null &&
        priorPath.isNotEmpty &&
        priorPath != archived) {
      if (!await CoffeeImageArchive.deleteIfOwnedStrict(priorPath)) {
        await _store.journalOwnedImagePath(priorPath);
      }
    }
    // Version seed is post-commit enrichment — never deny a durable reading.
    try {
      await _versions?.seedOriginal(
        rootId: persisted.id,
        kind: ReadingVersionKind.coffee,
        data: ReadingVersionPayload.coffee(persisted),
      );
    } catch (_) {}
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
    final stamp = captureOwner();
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
    await _saveOwned(reading, stamp);
    // Version seed is post-commit enrichment — its failure must never
    // turn an already-durable reading into a user-visible failure (which
    // would risk a caller retrying and repeating the paid provider op).
    try {
      await _versions?.seedOriginal(
        rootId: reading.id,
        kind: ReadingVersionKind.coffee,
        data: ReadingVersionPayload.coffee(reading),
      );
    } catch (_) {}
    return reading;
  }

  Future<CoffeeReading> restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
    String? expectedOwnerId,
    int? expectedEpoch,
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
    final stamp = (
      ownerId: expectedOwnerId ?? captureOwner().ownerId,
      epoch: expectedEpoch ?? captureOwner().epoch,
    );
    await _saveOwned(reading, stamp);
    // Version seed is post-commit enrichment — its failure must never
    // turn an already-durable reading into a user-visible failure.
    try {
      await _versions?.seedOriginal(
        rootId: reading.id,
        kind: ReadingVersionKind.coffee,
        data: ReadingVersionPayload.coffee(reading),
      );
    } catch (_) {}
    return reading;
  }

  /// Reading metadata is the durable commit point; version history is
  /// secondary enrichment. Order matters: (1) a NON-MUTATING duplicate
  /// check — safe before any commit because the coffee fingerprint is
  /// text-only and never depends on `imagePath` — (2) only then create a
  /// new image candidate (never for a duplicate/no-op, so nothing is ever
  /// orphaned by one), (3) durably save the merged reading, rolling back
  /// ONLY a newly-created candidate (never a prior committed image) if
  /// that save fails, and (4) append the version revision best-effort
  /// AFTER the reading itself is durable.
  Future<CoffeeReinterpretResult> reinterpret({
    required CoffeeReading current,
    required CoffeeImagePick image,
  }) async {
    final stamp = captureOwner();
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

    final versions = _versions;
    if (versions != null) {
      final probe = current.copyWith(
        coffeeResultContract: fresh.coffeeResultContract,
        overall: fresh.overall,
        love: fresh.love,
        career: fresh.career,
        money: fresh.money,
        nearFuture: fresh.nearFuture,
        takeaway: fresh.takeaway,
        visualObservation: fresh.visualObservation,
        symbols: fresh.symbols,
      );
      final probeFingerprint = ReadingVersionFingerprint.of(
        ReadingVersionPayload.coffee(probe),
        ReadingVersionKind.coffee,
      );
      // Missing group: compare against the CURRENT durable reading —
      // never invent a baseline by mutating version state first.
      final activeFingerprint =
          versions.groupFor(current.id)?.activeEntry?.fingerprint ??
              ReadingVersionFingerprint.of(
                ReadingVersionPayload.coffee(current),
                ReadingVersionKind.coffee,
              );
      if (activeFingerprint == probeFingerprint) {
        return CoffeeReinterpretResult(reading: current, versionAdded: false);
      }
    }

    final createdCandidate = current.imagePath == null;
    final imagePath = current.imagePath ??
        await _persistImage(
          readingId: current.id,
          sourcePath: image.path,
        );
    final merged = CoffeeReading(
      id: current.id,
      createdAt: current.createdAt,
      imagePath: imagePath,
      coffeeResultContract: fresh.coffeeResultContract,
      overall: fresh.overall,
      love: fresh.love,
      career: fresh.career,
      money: fresh.money,
      nearFuture: fresh.nearFuture,
      takeaway: fresh.takeaway,
      visualObservation: fresh.visualObservation,
      symbols: fresh.symbols,
    );

    try {
      await _saveOwned(merged, stamp);
    } catch (_) {
      if (createdCandidate) {
        if (!await CoffeeImageArchive.deleteIfOwnedStrict(imagePath)) {
          await _store.journalOwnedImagePath(imagePath);
        }
      }
      rethrow;
    }

    var added = false;
    if (versions != null) {
      try {
        // Missing group: establish PREVIOUS current as Original, then append.
        final existing = versions.groupFor(current.id);
        if (existing == null || existing.entries.isEmpty) {
          await versions.seedOriginal(
            rootId: current.id,
            kind: ReadingVersionKind.coffee,
            data: ReadingVersionPayload.coffee(current),
          );
        }
        final result = await versions.tryAppendRevision(
          rootId: current.id,
          kind: ReadingVersionKind.coffee,
          data: ReadingVersionPayload.coffee(merged),
        );
        added = result.added;
      } catch (_) {
        // Enrichment failure must not turn the already-durable reading
        // into a user-visible "analysis failed".
      }
    }
    return CoffeeReinterpretResult(reading: merged, versionAdded: added);
  }
}
