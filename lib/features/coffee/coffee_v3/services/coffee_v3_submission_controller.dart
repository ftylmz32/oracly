/// Coffee V3 three-photo submission foundation — persists, validates, creates
/// exactly one `three_view_v3` operation, stages the three namespaced slots
/// sequentially (one byte array at a time), resumes after restart and hands
/// off terminal results. Separate from Coffee V2 by design; it reuses only
/// the version-agnostic primitives (normalizer seam, byte loader, checksum,
/// image limit, intention contract, ReadingLiveFlow, staged-image gateway).
///
/// Never calls a provider, never claims/executes a pipeline, never touches
/// result prose — completion stays server-owned.
library;

import 'dart:io';

import '../../../ai/production/transport/image_normalizer.dart';
import '../../../reading_operation/models/reading_operation_status.dart';
import '../../../reading_operation/services/reading_live_flow.dart';
import '../../../reading_operation/services/reading_staged_image_gateway.dart';
import '../../coffee_v2/models/coffee_v2_intention.dart';
import '../../coffee_v2/services/coffee_v2_byte_loader.dart';
import '../../coffee_v2/services/coffee_v2_checksum.dart';
import '../../coffee_v2/services/coffee_v2_image_limits.dart';
import '../../coffee_v2/services/coffee_v2_normalizer.dart';
import '../../models/coffee_image_pick.dart';
import '../models/coffee_v3_capture_contract.dart';
import '../models/coffee_v3_photo_asset.dart';
import '../models/coffee_v3_photo_slot.dart';
import '../models/coffee_v3_stage_state.dart';
import '../models/coffee_v3_submission_record.dart';
import 'coffee_v3_creation_gate.dart';
import 'coffee_v3_normalizer.dart';
import 'coffee_v3_submission_store.dart';
import 'coffee_v3_validation.dart';
import 'coffee_v3_work_files.dart';

enum CoffeeV3SlotSelectionFailure {
  missingFile,
  unsupportedFormat,
  tooLarge,
  normalizeFailed,

  /// Same checksum as another V3 slot's photo.
  duplicate,
}

class CoffeeV3SlotSelectionResult {
  const CoffeeV3SlotSelectionResult.success(this.asset)
      : failure = null,
        duplicateOf = null;

  const CoffeeV3SlotSelectionResult.failure(this.failure, {this.duplicateOf})
      : asset = null;

  final CoffeeV3PhotoAsset? asset;
  final CoffeeV3SlotSelectionFailure? failure;
  final CoffeeV3PhotoSlot? duplicateOf;

  bool get isSuccess => asset != null;
}

enum CoffeeV3SubmissionOutcome {
  /// All three slots staged; the operation awaits server-owned processing.
  completedStaging,

  /// Transport / backend failure while creating or staging — retryable,
  /// nothing lost (same sourceRequestId / same operationId on retry).
  retryableFailure,

  /// The backend refused to create a `three_view_v3` operation (400 — e.g.
  /// its V3 creation flag is off). No operation bound, draft intact.
  createRejected,

  /// Client creation gate closed (rollout flag off or non-Turkish UI).
  creationDisabled,

  /// Not all three confirmed / a duplicate / no valid intention.
  blockedByValidation,

  activeSubmissionInProgress,

  /// Nothing active to resume.
  notEligible,
}

class CoffeeV3SubmissionController {
  CoffeeV3SubmissionController({
    required this.flow,
    required this.stagedImages,
    required this.store,
    CoffeeV2ByteLoader? byteLoader,
    CoffeeV2Normalizer? normalizer,
    ImageNormalizeMessages messages = coffeeV2DefaultNormalizeMessages,
    bool Function()? creationAllowed,
    String Function()? newSourceRequestId,
  })  : byteLoader = byteLoader ?? const FileCoffeeV2ByteLoader(),
        normalizer = normalizer ?? DefaultCoffeeV3Normalizer(messages),
        _messages = messages,
        _creationAllowed =
            creationAllowed ?? (() => CoffeeV3CreationGate.creationAllowed),
        _newSourceRequestId = newSourceRequestId ??
            (() =>
                '$coffeeV3SourceRequestPrefix${DateTime.now().microsecondsSinceEpoch}'),
        _record = CoffeeV3SubmissionRecord.empty();

  final ReadingLiveFlow flow;
  final ReadingStagedImageGateway stagedImages;
  final CoffeeV3SubmissionStore store;
  final CoffeeV2ByteLoader byteLoader;
  final CoffeeV2Normalizer normalizer;
  final ImageNormalizeMessages _messages;
  final bool Function() _creationAllowed;
  final String Function() _newSourceRequestId;

  CoffeeV3SubmissionRecord _record;

  CoffeeV3SubmissionRecord get record => _record;

  CoffeeV3PhotoAsset? assetFor(CoffeeV3PhotoSlot slot) =>
      _record.slots[slot]?.asset;

  Map<CoffeeV3PhotoSlot, CoffeeV3PhotoAsset?> get _assets => {
        for (final slot in coffeeV3CanonicalSlotOrder) slot: assetFor(slot),
      };

  bool get allConfirmed => coffeeV3CanonicalSlotOrder.every(
        (slot) => _record.slots[slot]?.confirmed == true,
      );

  CoffeeV3ValidationIssue? get validationIssue =>
      CoffeeV3Validation.evaluate(_record);

  bool get hasValidIntention =>
      canonicalCoffeeV2Intention(_record.intention) != null;

  /// Live creation gate (rollout flag + Turkish UI), re-read on every call.
  bool get creationAllowed => _creationAllowed();

  /// Every precondition for creating the operation holds right now.
  bool get readyToCreate =>
      _record.isDraft &&
      validationIssue == null &&
      hasValidIntention &&
      creationAllowed;

  Future<bool> setIntention(String? value) async {
    _requireDraft();
    final canonical = canonicalCoffeeV2Intention(value);
    await _commitRecord(_record.copyWith(intention: canonical));
    return canonical != null;
  }

  /// Normalizes + checksums [picked] and, only if it is valid AND distinct
  /// from the other three slots, commits it to [slot] as confirmed. Any
  /// failure leaves the slot's previous confirmed asset untouched.
  Future<CoffeeV3SlotSelectionResult> selectSlot(
    CoffeeV3PhotoSlot slot,
    CoffeeImagePick picked,
  ) async {
    _requireDraft();
    final CoffeeImagePick normalized;
    try {
      normalized = await normalizer.normalize(picked);
    } on ImageNormalizeException catch (e) {
      return CoffeeV3SlotSelectionResult.failure(_classify(e));
    }
    final sizeBytes = await File(normalized.path).length();
    if (sizeBytes > CoffeeV2ImageLimits.maxBytes) {
      await _deleteFile(normalized.path);
      return const CoffeeV3SlotSelectionResult.failure(
        CoffeeV3SlotSelectionFailure.tooLarge,
      );
    }
    final asset = CoffeeV3PhotoAsset(
      slot: slot,
      path: normalized.path,
      mimeType: normalized.mimeType ?? 'image/jpeg',
      sha256: await CoffeeV2Checksum.sha256OfFile(normalized.path),
      sizeBytes: sizeBytes,
    );
    final duplicateOf = CoffeeV3Validation.duplicateOf(asset, _assets);
    if (duplicateOf != null) {
      await _deleteFile(normalized.path);
      return CoffeeV3SlotSelectionResult.failure(
        CoffeeV3SlotSelectionFailure.duplicate,
        duplicateOf: duplicateOf,
      );
    }
    final previousPath = assetFor(slot)?.path;
    await _commitRecord(
      _record.copyWith(
        slots: {
          ..._record.slots,
          slot: CoffeeV3SlotRecord(asset: asset, confirmed: true),
        },
      ),
    );
    // The replaced draft photo is released only AFTER the new one is
    // durably recorded.
    if (previousPath != null && previousPath != asset.path) {
      await _deleteFile(previousPath);
    }
    return CoffeeV3SlotSelectionResult.success(asset);
  }

  Future<void> clearSlot(CoffeeV3PhotoSlot slot) async {
    _requireDraft();
    final previousPath = assetFor(slot)?.path;
    await _commitRecord(
      _record.copyWith(
        slots: {..._record.slots, slot: const CoffeeV3SlotRecord()},
      ),
    );
    if (previousPath != null) await _deleteFile(previousPath);
  }

  Future<CoffeeV3SubmissionOutcome> beginSubmission() async {
    if (_record.isActive) {
      return CoffeeV3SubmissionOutcome.activeSubmissionInProgress;
    }
    if (!creationAllowed) return CoffeeV3SubmissionOutcome.creationDisabled;
    if (validationIssue != null) {
      return CoffeeV3SubmissionOutcome.blockedByValidation;
    }
    final intention = canonicalCoffeeV2Intention(_record.intention);
    if (intention == null) {
      return CoffeeV3SubmissionOutcome.blockedByValidation;
    }

    // Idempotency identity is durable BEFORE anything exists server-side:
    // an app kill between create and local bind re-submits this SAME id and
    // the backend's createIfAbsent returns the original operation.
    var sourceRequestId = _record.sourceRequestId;
    if (sourceRequestId == null) {
      sourceRequestId = _newSourceRequestId();
      await _commitRecord(
        _record.copyWith(sourceRequestId: sourceRequestId),
        requireDurableOwner: true,
      );
    }

    final begun = await flow.begin(
      readingType: ReadingType.coffee,
      sourceRequestId: sourceRequestId,
      intention: intention,
      coffeeInputContract: coffeeV2InputContract,
      coffeeCaptureContract: coffeeV3CaptureContract,
    );
    final snapshot = begun.snapshot;
    if (snapshot == null) {
      // Never remapped to V2, never staged, nothing bound locally.
      return begun.httpStatus == 400
          ? CoffeeV3SubmissionOutcome.createRejected
          : CoffeeV3SubmissionOutcome.retryableFailure;
    }
    // Exactly one operation for this three-photo submission; every stage
    // call and every later retry targets this SAME operationId.
    await _commitRecord(
      _record.copyWith(operationId: snapshot.operationId),
      requireDurableOwner: true,
    );
    return _stageSequentially();
  }

  Future<CoffeeV3SubmissionOutcome> retrySubmission() async {
    if (!_record.isActive) return CoffeeV3SubmissionOutcome.notEligible;
    return _stageSequentially();
  }

  Future<CoffeeV3SubmissionOutcome> _stageSequentially() async {
    final operationId = _record.operationId;
    if (operationId == null) return CoffeeV3SubmissionOutcome.notEligible;
    for (final slot in coffeeV3CanonicalSlotOrder) {
      final slotRecord = _record.slots[slot];
      if (slotRecord?.stageState == CoffeeV3StageState.staged) continue;
      final asset = slotRecord?.asset;
      if (asset == null) return CoffeeV3SubmissionOutcome.retryableFailure;
      // Sequential by construction: this slot's bytes are loaded, staged
      // and dropped before the next slot's bytes are ever read.
      final bytes = await byteLoader.loadBytes(asset.path);
      final ok = await stagedImages.stage(
        operationId: operationId,
        bytes: bytes,
        mimeType: asset.mimeType,
        slot: slot.wireValue,
      );
      if (!ok) return CoffeeV3SubmissionOutcome.retryableFailure;
      await _commitRecord(
        _record.copyWith(
          slots: {
            ..._record.slots,
            slot: slotRecord!.copyWith(stageState: CoffeeV3StageState.staged),
          },
        ),
        requireDurableOwner: true,
      );
    }
    return CoffeeV3SubmissionOutcome.completedStaging;
  }

  /// DRAFT: revalidates every slot file (a missing/changed file clears only
  /// that slot). ACTIVE: restored verbatim — bound identity is immutable.
  Future<void> recoverDraftOrSubmission() async {
    final loaded = store.load();
    if (loaded == null) {
      _record = CoffeeV3SubmissionRecord.empty();
      return;
    }
    if (loaded.isActive) {
      _record = loaded;
      return;
    }
    final revalidated = <CoffeeV3PhotoSlot, CoffeeV3SlotRecord>{};
    for (final slot in coffeeV3CanonicalSlotOrder) {
      final slotRecord = loaded.slots[slot] ?? const CoffeeV3SlotRecord();
      final asset = slotRecord.asset;
      revalidated[slot] = asset == null || await _assetStillValid(asset)
          ? slotRecord
          : const CoffeeV3SlotRecord();
    }
    final next = loaded.copyWith(slots: revalidated);
    _record = next;
    await store.save(next);
  }

  Future<bool> _assetStillValid(CoffeeV3PhotoAsset asset) async {
    // Persisted metadata is untrusted: a draft only ever adopts an app-owned
    // V3 working copy, never an arbitrary file path.
    if (!await CoffeeV3WorkFiles.isOwned(asset.path)) return false;
    final file = File(asset.path);
    if (!await file.exists()) return false;
    final size = await file.length();
    if (size != asset.sizeBytes || size > CoffeeV2ImageLimits.maxBytes) {
      return false;
    }
    return await CoffeeV2Checksum.sha256OfFile(asset.path) == asset.sha256;
  }

  /// DRAFT only: deletes this draft's V3 temp files and V3 metadata. Never
  /// touches V2, legacy pending operations, the server or saved readings.
  Future<void> cancelDraft() async {
    if (_record.isActive) {
      throw StateError('Cannot cancel an active Coffee V3 submission');
    }
    final previous = _record;
    if (store.ownerReady) {
      await store.clearDurable();
    } else {
      await store.clear();
    }
    _record = CoffeeV3SubmissionRecord.empty();
    await _deleteTempFiles(previous);
  }

  /// Upload-only data is released once the result is durable locally;
  /// operation/result identity stays until explicit acknowledgement.
  Future<void> onResultRestored(String resultId) async {
    final previous = _record;
    await _commitRecord(
      _record.copyWith(
        slots: CoffeeV3SubmissionRecord.empty().slots,
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
      _record.copyWith(slots: CoffeeV3SubmissionRecord.empty().slots),
      requireDurableOwner: true,
    );
    await _deleteTempFiles(previous);
  }

  /// New Cup / terminal handoff: the next V3 reading starts from a clean
  /// draft and therefore gets a fresh sourceRequestId.
  Future<void> acknowledgeTerminalHandoff() async {
    final operationId = _record.operationId;
    if (operationId != null) await store.acknowledgeDurable(operationId);
    await store.clearDurable();
    _record = CoffeeV3SubmissionRecord.empty();
  }

  Future<void> _deleteTempFiles(CoffeeV3SubmissionRecord record) async {
    for (final slotRecord in record.slots.values) {
      final path = slotRecord.asset?.path;
      if (path != null) await _deleteFile(path);
    }
  }

  /// Best-effort in-flow release of an app-owned V3 working copy only. A
  /// path that is not an owned V3 working file (camera/gallery original,
  /// tampered metadata, other feature) is never touched; anything left
  /// behind is reclaimed by the strict account-boundary purge.
  Future<void> _deleteFile(String path) async {
    await CoffeeV3WorkFiles.deleteIfOwnedStrict(path);
  }

  Future<void> _commitRecord(
    CoffeeV3SubmissionRecord next, {
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
        'Coffee V3 photos are immutable once an operation exists',
      );
    }
  }

  CoffeeV3SlotSelectionFailure _classify(ImageNormalizeException e) {
    if (e.message == _messages.missing || e.message == _messages.unreadable) {
      return CoffeeV3SlotSelectionFailure.missingFile;
    }
    if (e.message == _messages.unsupported) {
      return CoffeeV3SlotSelectionFailure.unsupportedFormat;
    }
    if (e.message == _messages.tooLarge) {
      return CoffeeV3SlotSelectionFailure.tooLarge;
    }
    return CoffeeV3SlotSelectionFailure.normalizeFailed;
  }
}
