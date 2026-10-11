/// Coffee V3 operation-creation gate: all three slots present and confirmed,
/// all three checksums PAIRWISE distinct. Client defense only — the
/// backend's staged-image duplicate guard stays authoritative.
library;

import '../models/coffee_v3_photo_asset.dart';
import '../models/coffee_v3_photo_slot.dart';
import '../models/coffee_v3_submission_record.dart';

enum CoffeeV3ValidationIssue { incomplete, duplicate }

abstract final class CoffeeV3Validation {
  CoffeeV3Validation._();

  /// The first other slot (canonical order) whose checksum equals
  /// [candidate]'s, or null. The candidate's own slot is ignored so a
  /// replacement is compared only against the OTHER three photos.
  static CoffeeV3PhotoSlot? duplicateOf(
    CoffeeV3PhotoAsset candidate,
    Map<CoffeeV3PhotoSlot, CoffeeV3PhotoAsset?> assets,
  ) {
    for (final slot in coffeeV3CanonicalSlotOrder) {
      if (slot == candidate.slot) continue;
      if (assets[slot]?.sha256 == candidate.sha256) return slot;
    }
    return null;
  }

  /// True when ANY two present assets share a checksum — every pair, not
  /// only adjacent ones.
  static bool hasDuplicate(Map<CoffeeV3PhotoSlot, CoffeeV3PhotoAsset?> assets) {
    final seen = <String>{};
    for (final slot in coffeeV3CanonicalSlotOrder) {
      final sha = assets[slot]?.sha256;
      if (sha == null) continue;
      if (!seen.add(sha)) return true;
    }
    return false;
  }

  static CoffeeV3ValidationIssue? evaluate(CoffeeV3SubmissionRecord record) {
    final assets = {
      for (final slot in coffeeV3CanonicalSlotOrder)
        slot: record.slots[slot]?.asset,
    };
    if (hasDuplicate(assets)) return CoffeeV3ValidationIssue.duplicate;
    final allConfirmed = coffeeV3CanonicalSlotOrder.every((slot) {
      final s = record.slots[slot];
      return s != null && s.confirmed && s.asset != null;
    });
    return allConfirmed ? null : CoffeeV3ValidationIssue.incomplete;
  }
}
