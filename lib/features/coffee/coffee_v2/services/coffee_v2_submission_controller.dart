/// Coffee V2 client foundation — represents, persists, validates, stages,
/// resumes and observes exactly three Coffee V2 source photos without ever
/// holding all three image byte arrays in memory at once, and without
/// changing legacy Coffee/Palm behavior.
///
/// This is infrastructure only (Phase 2C1): no camera UI, no production
/// routing. `beginSubmission`/`retrySubmission` create/continue exactly one
/// `ReadingOperation` via the existing `ReadingLiveFlow`/gem-and-wait
/// system, then stage the three slots sequentially through the existing
/// `ReadingStagedImageGateway`. Completion stays server-owned — this
/// controller never calls a provider and never claims/executes a pipeline.
library;

import 'dart:io';

import '../../../reading_operation/models/reading_operation_status.dart';
import '../../../reading_operation/services/reading_live_flow.dart';
import '../../../reading_operation/services/reading_staged_image_gateway.dart';
import '../../../ai/production/transport/image_normalizer.dart';
import '../../models/coffee_image_pick.dart';
import '../models/coffee_v2_photo_asset.dart';
import '../models/coffee_v2_photo_slot.dart';
import '../models/coffee_v2_stage_state.dart';
import '../models/coffee_v2_submission_record.dart';
import 'coffee_v2_byte_loader.dart';
import 'coffee_v2_checksum.dart';
import 'coffee_v2_image_limits.dart';
import 'coffee_v2_normalizer.dart';
import 'coffee_v2_submission_store.dart';
import 'coffee_v2_validation.dart';

enum CoffeeV2SlotSelectionFailure {
  missingFile,
  unsupportedFormat,
  tooLarge,
  normalizeFailed,
}

class CoffeeV2SlotSelectionResult {
  const CoffeeV2SlotSelectionResult.success(this.asset) : failure = null;

  const CoffeeV2SlotSelectionResult.failure(this.failure) : asset = null;

  final CoffeeV2PhotoAsset? asset;
  final CoffeeV2SlotSelectionFailure? failure;

  bool get isSuccess => asset != null;
}

enum CoffeeV2SubmissionOutcome {
  /// All three slots staged; the operation now awaits server-owned
  /// processing exactly like legacy Coffee/Palm.
  completedStaging,

  /// A stage call failed (transport/backend) — retryable, no data lost.
  retryableFailure,

  /// `beginSubmission` was called while validation was not satisfied
  /// (not all three confirmed, or a duplicate) — no operation was created.
  blockedByValidation,

  /// `beginSubmission` was called while a submission was already active.
  activeSubmissionInProgress,

  /// `retrySubmission` was called with no active submission to resume.
  notEligible,
}

class CoffeeV2SubmissionController {
  CoffeeV2SubmissionController({
    required this.flow,
    required this.stagedImages,
    required this.store,
    CoffeeV2ByteLoader? byteLoader,
    CoffeeV2Normalizer? normalizer,
    ImageNormalizeMessages messages = coffeeV2DefaultNormalizeMessages,
  }) : byteLoader = byteLoader ?? const FileCoffeeV2ByteLoader(),
       normalizer = normalizer ?? DefaultCoffeeV2Normalizer(messages),
       _messages = messages,
       _record = CoffeeV2SubmissionRecord.empty();

  final ReadingLiveFlow flow;
  final ReadingStagedImageGateway stagedImages;
  final CoffeeV2SubmissionStore store;
  final CoffeeV2ByteLoader byteLoader;
  final CoffeeV2Normalizer normalizer;
  final ImageNormalizeMessages _messages;

  CoffeeV2SubmissionRecord _record;

  CoffeeV2SubmissionRecord get record => _record;

  CoffeeV2PhotoAsset? assetFor(CoffeeV2PhotoSlot slot) =>
      _record.slots[slot]?.asset;

  bool get allThreeConfirmed => coffeeV2CanonicalSlotOrder.every(
    (slot) => _record.slots[slot]?.confirmed == true,
  );

  CoffeeV2ValidationIssue? get validationIssue =>
      CoffeeV2Validation.evaluate(_record);

  bool get hasDuplicate =>
      CoffeeV2Validation.duplicateIssue({
        for (final slot in coffeeV2CanonicalSlotOrder) slot: assetFor(slot),
      }) !=
      null;

  /// True only while still in DRAFT and every gate in spec §8 is satisfied.
  bool get allThreeReady => _record.isDraft && validationIssue == null;

  Future<CoffeeV2SlotSelectionResult> setSlot(
    CoffeeV2PhotoSlot slot,
    CoffeeImagePick picked,
  ) async {
    _requireDraft();
    try {
      final normalized = await normalizer.normalize(picked);
      final sizeBytes = await File(normalized.path).length();
      // Defense-in-depth: enforced regardless of which `CoffeeV2Normalizer`
      // is plugged in, not only the default one wrapping `ImageNormalizer`.
      if (sizeBytes > CoffeeV2ImageLimits.maxBytes) {
        return CoffeeV2SlotSelectionResult.failure(
          CoffeeV2SlotSelectionFailure.tooLarge,
        );
      }
      final checksum = await CoffeeV2Checksum.sha256OfFile(normalized.path);
      final asset = CoffeeV2PhotoAsset(
        slot: slot,
        path: normalized.path,
        mimeType: normalized.mimeType ?? 'image/jpeg',
        sha256: checksum,
        sizeBytes: sizeBytes,
      );
      await _commitRecord(
        _record.copyWith(
          slots: {
            ..._record.slots,
            slot: CoffeeV2SlotRecord(asset: asset),
          },
        ),
      );
      return CoffeeV2SlotSelectionResult.success(asset);
    } on ImageNormalizeException catch (e) {
      return CoffeeV2SlotSelectionResult.failure(_classify(e));
    }
  }

  /// Same operation as [setSlot] — replacing a DRAFT slot only ever
  /// touches that one slot.
  Future<CoffeeV2SlotSelectionResult> replaceSlot(
    CoffeeV2PhotoSlot slot,
    CoffeeImagePick picked,
  ) => setSlot(slot, picked);

  Future<void> clearSlot(CoffeeV2PhotoSlot slot) async {
    _requireDraft();
    await _commitRecord(
      _record.copyWith(
        slots: {..._record.slots, slot: const CoffeeV2SlotRecord()},
      ),
    );
  }

  Future<void> confirmSlot(CoffeeV2PhotoSlot slot) async {
    _requireDraft();
    final existing = _record.slots[slot];
    if (existing?.asset == null) return;
    await _commitRecord(
      _record.copyWith(
        slots: {..._record.slots, slot: existing!.copyWith(confirmed: true)},
      ),
    );
  }

  Future<CoffeeV2SubmissionOutcome> beginSubmission(
    String sourceRequestId,
  ) async {
    if (_record.isActive) {
      return CoffeeV2SubmissionOutcome.activeSubmissionInProgress;
    }
    if (validationIssue != null) {
      return CoffeeV2SubmissionOutcome.blockedByValidation;
    }

    // Persist idempotency identity BEFORE creating anything server-side.
    // If the app dies after create succeeds but before operationId binding
    // lands locally, restart can re-submit this SAME sourceRequestId and the
    // backend's createIfAbsent contract returns the original operation.
    final persistedSource = _record.sourceRequestId?.trim();
    final durableSourceRequestId =
        persistedSource != null && persistedSource.isNotEmpty
            ? persistedSource
            : sourceRequestId;
    if (persistedSource == null || persistedSource.isEmpty) {
      await _commitRecord(
        _record.copyWith(sourceRequestId: durableSourceRequestId),
        requireDurableOwner: true,
      );
    }

    final begun = await flow.begin(
      readingType: ReadingType.coffee,
      sourceRequestId: durableSourceRequestId,
    );
    final snapshot = begun.snapshot;
    if (snapshot == null) return CoffeeV2SubmissionOutcome.retryableFailure;
    // Exactly one operation for this whole three-photo submission — every
    // subsequent stage call below, and any later retry, targets this SAME
    // operationId. Never re-entered: `_record.isActive` above guards it.
    await _commitRecord(
      _record.copyWith(operationId: snapshot.operationId),
      requireDurableOwner: true,
    );
    return _stageSequentially();
  }

  Future<CoffeeV2SubmissionOutcome> retrySubmission() async {
    if (!_record.isActive) return CoffeeV2SubmissionOutcome.notEligible;
    return _stageSequentially();
  }

  Future<CoffeeV2SubmissionOutcome> _stageSequentially() async {
    final operationId = _record.operationId;
    if (operationId == null) return CoffeeV2SubmissionOutcome.notEligible;
    for (final slot in coffeeV2CanonicalSlotOrder) {
      final slotRecord = _record.slots[slot];
      if (slotRecord?.stageState == CoffeeV2StageState.staged) continue;
      final asset = slotRecord?.asset;
      if (asset == null) return CoffeeV2SubmissionOutcome.retryableFailure;
      // Sequential by construction: the next slot's bytes are not loaded
      // until this `await` (load, then stage) has fully resolved, and the
      // loaded `bytes` reference falls out of scope at the end of this
      // loop iteration — never held alongside the next slot's bytes.
      final bytes = await byteLoader.loadBytes(asset.path);
      final ok = await stagedImages.stage(
        operationId: operationId,
        bytes: bytes,
        mimeType: asset.mimeType,
        slot: slot.wireValue,
      );
      if (!ok) return CoffeeV2SubmissionOutcome.retryableFailure;
      await _commitRecord(
        _record.copyWith(
          slots: {
            ..._record.slots,
            slot: slotRecord!.copyWith(stageState: CoffeeV2StageState.staged),
          },
        ),
        requireDurableOwner: true,
      );
    }
    return CoffeeV2SubmissionOutcome.completedStaging;
  }

  /// Restores DRAFT (revalidating each slot's file) or ACTIVE (restored
  /// as-is, operationId/bound assets untouched) state after process death.
  Future<void> recoverDraftOrSubmission() async {
    final loaded = store.load();
    if (loaded == null) {
      _record = CoffeeV2SubmissionRecord.empty();
      return;
    }
    if (loaded.isActive) {
      // ACTIVE restart: operationId and bound assets are immutable once
      // set — restore verbatim, never re-derive, never create a second
      // operation.
      _record = loaded;
      return;
    }
    final revalidated = <CoffeeV2PhotoSlot, CoffeeV2SlotRecord>{};
    for (final slot in coffeeV2CanonicalSlotOrder) {
      final slotRecord = loaded.slots[slot] ?? const CoffeeV2SlotRecord();
      final asset = slotRecord.asset;
      if (asset == null) {
        revalidated[slot] = slotRecord;
        continue;
      }
      if (await _slotAssetStillValid(asset)) {
        revalidated[slot] = slotRecord;
      } else {
        // Missing/corrupt local file invalidates only this slot — the
        // other valid draft photos are preserved.
        revalidated[slot] = const CoffeeV2SlotRecord();
      }
    }
    await _commitRecord(loaded.copyWith(slots: revalidated));
  }

  Future<bool> _slotAssetStillValid(CoffeeV2PhotoAsset asset) async {
    final file = File(asset.path);
    if (!await file.exists()) return false;
    final size = await file.length();
    if (size != asset.sizeBytes) return false;
    if (size > CoffeeV2ImageLimits.maxBytes) return false;
    final checksum = await CoffeeV2Checksum.sha256OfFile(asset.path);
    return checksum == asset.sha256;
  }

  /// DRAFT cancellation before any operation exists — delete this draft's
  /// temporary normalized files and clear its metadata.
  Future<void> cancelDraft() async {
    if (_record.isActive) {
      throw StateError('Cannot cancel an active Coffee V2 submission');
    }
    final previous = _record;
    if (store.ownerReady) {
      await store.clearDurable();
    } else {
      await store.clear();
    }
    _record = CoffeeV2SubmissionRecord.empty();
    await _deleteTempFiles(previous);
  }

  /// Upload-only data can be released after restoration, but operation and
  /// result identity remain durable until explicit acknowledgement.
  Future<void> onResultRestored(String resultId) async {
    final previous = _record;
    await _commitRecord(
      _record.copyWith(
        slots: CoffeeV2SubmissionRecord.empty().slots,
        resultId: resultId,
        resultPendingAcknowledgement: true,
      ),
      requireDurableOwner: true,
    );
    await _deleteTempFiles(previous);
  }

  Future<void> onTerminalFailure() async {
    final previous = _record;
    await _commitRecord(
      _record.copyWith(slots: CoffeeV2SubmissionRecord.empty().slots),
      requireDurableOwner: true,
    );
    await _deleteTempFiles(previous);
  }

  Future<void> acknowledgeTerminalHandoff() async {
    final operationId = _record.operationId;
    if (operationId != null) await store.acknowledgeDurable(operationId);
    await store.clearDurable();
    _record = CoffeeV2SubmissionRecord.empty();
  }

  Future<void> _deleteTempFiles(CoffeeV2SubmissionRecord record) async {
    for (final slotRecord in record.slots.values) {
      final path = slotRecord.asset?.path;
      if (path == null) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort cleanup, mirroring the existing archive philosophy.
      }
    }
  }

  Future<void> _commitRecord(
    CoffeeV2SubmissionRecord next, {
    bool requireDurableOwner = false,
  }) async {
    if (requireDurableOwner) {
      await store.saveDurable(next);
    } else {
      await store.save(next);
    }
    _record = next;
  }

  void _requireDraft() {
    if (_record.isActive) {
      throw StateError(
        'Coffee V2 slots are immutable once an active submission exists',
      );
    }
  }

  CoffeeV2SlotSelectionFailure _classify(ImageNormalizeException e) {
    if (e.message == _messages.missing) {
      return CoffeeV2SlotSelectionFailure.missingFile;
    }
    if (e.message == _messages.unreadable) {
      return CoffeeV2SlotSelectionFailure.missingFile;
    }
    if (e.message == _messages.unsupported) {
      return CoffeeV2SlotSelectionFailure.unsupportedFormat;
    }
    if (e.message == _messages.tooLarge) {
      return CoffeeV2SlotSelectionFailure.tooLarge;
    }
    return CoffeeV2SlotSelectionFailure.normalizeFailed;
  }
}
