/// Persisted Coffee V2 draft/submission state. Only safe local metadata —
/// never image bytes, base64, auth tokens, App Check tokens, or provider
/// payloads. `operationId == null` is the entire distinction between DRAFT
/// (still selecting/replacing photos) and ACTIVE SUBMISSION (all three
/// confirmed, one operation created, staging in progress or complete).
library;

import 'coffee_v2_photo_asset.dart';
import 'coffee_v2_photo_slot.dart';
import 'coffee_v2_stage_state.dart';

class CoffeeV2SlotRecord {
  const CoffeeV2SlotRecord({
    this.asset,
    this.confirmed = false,
    this.stageState = CoffeeV2StageState.notStaged,
  });

  final CoffeeV2PhotoAsset? asset;
  final bool confirmed;
  final CoffeeV2StageState stageState;

  CoffeeV2SlotRecord copyWith({
    CoffeeV2PhotoAsset? asset,
    bool? confirmed,
    CoffeeV2StageState? stageState,
  }) {
    return CoffeeV2SlotRecord(
      asset: asset ?? this.asset,
      confirmed: confirmed ?? this.confirmed,
      stageState: stageState ?? this.stageState,
    );
  }

  Map<String, dynamic> toJson() => {
    if (asset != null) 'asset': asset!.toJson(),
    'confirmed': confirmed,
    'stageState': coffeeV2StageStateWire(stageState),
  };

  static CoffeeV2SlotRecord fromJson(Object? json) {
    if (json is! Map) return const CoffeeV2SlotRecord();
    return CoffeeV2SlotRecord(
      asset: CoffeeV2PhotoAsset.fromJson(json['asset']),
      confirmed: json['confirmed'] == true,
      stageState: coffeeV2StageStateFromWire(json['stageState'] as String?),
    );
  }
}

class CoffeeV2SubmissionRecord {
  const CoffeeV2SubmissionRecord({
    required this.slots,
    this.ownerId,
    this.operationId,
    this.sourceRequestId,
    this.resultId,
    this.resultPendingAcknowledgement = false,
  });

  /// operationId == null => DRAFT. operationId != null => ACTIVE SUBMISSION.
  final String? ownerId;
  final String? operationId;
  final String? sourceRequestId;
  final String? resultId;
  final bool resultPendingAcknowledgement;
  final Map<CoffeeV2PhotoSlot, CoffeeV2SlotRecord> slots;

  bool get isActive => operationId != null;
  bool get isDraft => operationId == null;

  static CoffeeV2SubmissionRecord empty() => CoffeeV2SubmissionRecord(
    slots: {
      for (final slot in coffeeV2CanonicalSlotOrder)
        slot: const CoffeeV2SlotRecord(),
    },
  );

  CoffeeV2SubmissionRecord copyWith({
    Object? ownerId = _unset,
    Object? operationId = _unset,
    Object? sourceRequestId = _unset,
    Object? resultId = _unset,
    bool? resultPendingAcknowledgement,
    Map<CoffeeV2PhotoSlot, CoffeeV2SlotRecord>? slots,
  }) {
    return CoffeeV2SubmissionRecord(
      ownerId: ownerId == _unset ? this.ownerId : ownerId as String?,
      operationId: operationId == _unset
          ? this.operationId
          : operationId as String?,
      sourceRequestId: sourceRequestId == _unset
          ? this.sourceRequestId
          : sourceRequestId as String?,
      resultId: resultId == _unset ? this.resultId : resultId as String?,
      resultPendingAcknowledgement:
          resultPendingAcknowledgement ?? this.resultPendingAcknowledgement,
      slots: slots ?? this.slots,
    );
  }

  Map<String, dynamic> toJson() => {
    if (ownerId != null) 'ownerId': ownerId,
    if (operationId != null) 'operationId': operationId,
    if (sourceRequestId != null) 'sourceRequestId': sourceRequestId,
    if (resultId != null) 'resultId': resultId,
    'resultPendingAcknowledgement': resultPendingAcknowledgement,
    'slots': {
      for (final entry in slots.entries)
        entry.key.wireValue: entry.value.toJson(),
    },
  };

  static CoffeeV2SubmissionRecord fromJson(Object? json) {
    if (json is! Map) return CoffeeV2SubmissionRecord.empty();
    final rawSlots = json['slots'];
    final slots = <CoffeeV2PhotoSlot, CoffeeV2SlotRecord>{};
    for (final slot in coffeeV2CanonicalSlotOrder) {
      final rawSlot = rawSlots is Map ? rawSlots[slot.wireValue] : null;
      slots[slot] = CoffeeV2SlotRecord.fromJson(rawSlot);
    }
    final operationId = json['operationId'];
    final sourceRequestId = json['sourceRequestId'];
    final ownerId = json['ownerId'];
    final resultId = json['resultId'];
    return CoffeeV2SubmissionRecord(
      ownerId: ownerId is String && ownerId.isNotEmpty ? ownerId : null,
      operationId: operationId is String && operationId.isNotEmpty
          ? operationId
          : null,
      sourceRequestId: sourceRequestId is String && sourceRequestId.isNotEmpty
          ? sourceRequestId
          : null,
      resultId: resultId is String && resultId.isNotEmpty ? resultId : null,
      resultPendingAcknowledgement:
          json['resultPendingAcknowledgement'] == true,
      slots: slots,
    );
  }
}

const Object _unset = Object();
