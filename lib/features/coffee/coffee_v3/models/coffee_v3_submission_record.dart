/// Persisted Coffee V3 draft/submission state — safe local metadata only.
/// `operationId == null` is DRAFT (photos still editable); non-null is
/// ACTIVE (one `three_view_v3` operation exists; photos are bound and
/// immutable). Every persisted record carries `captureContract ==
/// three_view_v3`; a missing / unknown / different marker (including the
/// retired `four_view_v3`) is NOT a current V3 record and
/// [CoffeeV3SubmissionRecord.fromJson] throws (fail closed: the store
/// reports it as blocked, it is never reinterpreted as three photos).
///
/// Schema versioning: every record written now carries `schemaVersion: 1`.
/// A record without `schemaVersion` but with a valid `three_view_v3` marker
/// IS schema 1 — same shape — and is accepted as-is, then rewritten with the
/// explicit version on its next normal save (no field is dropped: owner,
/// operation, sourceRequestId, intention, slots, staging, result
/// acknowledgement all round-trip). Any other version (future, zero,
/// negative, non-integer) fails closed and is never interpreted. The
/// storage key stays `coffee_v3_submission` — renaming it would orphan
/// existing drafts / ACTIVE operations; the explicit version guards it.
library;

import 'coffee_v3_capture_contract.dart';
import 'coffee_v3_photo_asset.dart';
import 'coffee_v3_photo_slot.dart';
import 'coffee_v3_stage_state.dart';

class CoffeeV3SlotRecord {
  const CoffeeV3SlotRecord({
    this.asset,
    this.confirmed = false,
    this.stageState = CoffeeV3StageState.notStaged,
  });

  final CoffeeV3PhotoAsset? asset;
  final bool confirmed;
  final CoffeeV3StageState stageState;

  CoffeeV3SlotRecord copyWith({bool? confirmed, CoffeeV3StageState? stageState}) {
    return CoffeeV3SlotRecord(
      asset: asset,
      confirmed: confirmed ?? this.confirmed,
      stageState: stageState ?? this.stageState,
    );
  }

  Map<String, dynamic> toJson() => {
        if (asset != null) 'asset': asset!.toJson(),
        'confirmed': confirmed,
        'stageState': coffeeV3StageStateWire(stageState),
      };

  static CoffeeV3SlotRecord fromJson(Object? json, CoffeeV3PhotoSlot slot) {
    if (json is! Map) return const CoffeeV3SlotRecord();
    final asset = CoffeeV3PhotoAsset.fromJson(json['asset']);
    return CoffeeV3SlotRecord(
      // An asset filed under the wrong slot is never trusted.
      asset: asset?.slot == slot ? asset : null,
      confirmed: json['confirmed'] == true && asset?.slot == slot,
      stageState: coffeeV3StageStateFromWire(json['stageState'] as String?),
    );
  }
}

/// The only V3 record schema this client reads or writes.
const int coffeeV3SubmissionSchemaVersion = 1;

class CoffeeV3SubmissionRecord {
  const CoffeeV3SubmissionRecord({
    required this.slots,
    this.ownerId,
    this.operationId,
    this.sourceRequestId,
    this.intention,
    this.resultId,
    this.resultPendingAcknowledgement = false,
  });

  /// Always the current client contract — a record is only ever built for
  /// (and parsed as) `three_view_v3`.
  String get captureContract => coffeeV3CaptureContract;

  final String? ownerId;
  final String? operationId;
  final String? sourceRequestId;
  final String? intention;
  final String? resultId;
  final bool resultPendingAcknowledgement;
  final Map<CoffeeV3PhotoSlot, CoffeeV3SlotRecord> slots;

  bool get isActive => operationId != null;
  bool get isDraft => operationId == null;

  bool get hasAnyAsset => slots.values.any((s) => s.asset != null);

  static CoffeeV3SubmissionRecord empty() => CoffeeV3SubmissionRecord(
        slots: {
          for (final slot in coffeeV3CanonicalSlotOrder)
            slot: const CoffeeV3SlotRecord(),
        },
      );

  CoffeeV3SubmissionRecord copyWith({
    Object? ownerId = _unset,
    Object? operationId = _unset,
    Object? sourceRequestId = _unset,
    Object? intention = _unset,
    Object? resultId = _unset,
    bool? resultPendingAcknowledgement,
    Map<CoffeeV3PhotoSlot, CoffeeV3SlotRecord>? slots,
  }) {
    return CoffeeV3SubmissionRecord(
      ownerId: ownerId == _unset ? this.ownerId : ownerId as String?,
      operationId:
          operationId == _unset ? this.operationId : operationId as String?,
      sourceRequestId: sourceRequestId == _unset
          ? this.sourceRequestId
          : sourceRequestId as String?,
      intention: intention == _unset ? this.intention : intention as String?,
      resultId: resultId == _unset ? this.resultId : resultId as String?,
      resultPendingAcknowledgement:
          resultPendingAcknowledgement ?? this.resultPendingAcknowledgement,
      slots: slots ?? this.slots,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': coffeeV3SubmissionSchemaVersion,
        'captureContract': coffeeV3CaptureContract,
        if (ownerId != null) 'ownerId': ownerId,
        if (operationId != null) 'operationId': operationId,
        if (sourceRequestId != null) 'sourceRequestId': sourceRequestId,
        if (intention != null) 'intention': intention,
        if (resultId != null) 'resultId': resultId,
        'resultPendingAcknowledgement': resultPendingAcknowledgement,
        'slots': {
          for (final entry in slots.entries)
            entry.key.wireValue: entry.value.toJson(),
        },
      };

  /// Throws [FormatException] unless `captureContract == three_view_v3` and
  /// the schema is 1 (explicit, or absent = schema 1).
  static CoffeeV3SubmissionRecord fromJson(Object? json) {
    if (json is! Map || json['captureContract'] != coffeeV3CaptureContract) {
      throw const FormatException('unsupported_coffee_v3_capture_contract');
    }
    if (json.containsKey('schemaVersion') &&
        json['schemaVersion'] != coffeeV3SubmissionSchemaVersion) {
      throw const FormatException('unsupported_coffee_v3_schema_version');
    }
    final rawSlots = json['slots'];
    final slots = <CoffeeV3PhotoSlot, CoffeeV3SlotRecord>{
      for (final slot in coffeeV3CanonicalSlotOrder)
        slot: CoffeeV3SlotRecord.fromJson(
          rawSlots is Map ? rawSlots[slot.wireValue] : null,
          slot,
        ),
    };
    String? text(Object? v) => v is String && v.isNotEmpty ? v : null;
    return CoffeeV3SubmissionRecord(
      ownerId: text(json['ownerId']),
      operationId: text(json['operationId']),
      sourceRequestId: text(json['sourceRequestId']),
      intention: text(json['intention']),
      resultId: text(json['resultId']),
      resultPendingAcknowledgement:
          json['resultPendingAcknowledgement'] == true,
      slots: slots,
    );
  }
}

const Object _unset = Object();
