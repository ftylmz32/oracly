/// Locked operation-creation gate (spec §7/§8): three distinct checksums,
/// all three confirmed, before a `ReadingOperation` may ever be created.
/// This is client-side defense; the backend's Phase 2A duplicate guard
/// remains authoritative and is never relaxed by this existing locally.
library;

import '../models/coffee_v2_photo_asset.dart';
import '../models/coffee_v2_photo_slot.dart' show CoffeeV2PhotoSlot;
import '../models/coffee_v2_submission_record.dart';

enum CoffeeV2ValidationIssue {
  incomplete,
  duplicatePrimarySecondary,
  duplicatePrimarySaucer,
  duplicateSecondarySaucer,
}

abstract final class CoffeeV2Validation {
  CoffeeV2Validation._();

  static CoffeeV2ValidationIssue? duplicateIssue(
    Map<CoffeeV2PhotoSlot, CoffeeV2PhotoAsset?> assets,
  ) {
    final primary = assets[CoffeeV2PhotoSlot.cupPrimary]?.sha256;
    final secondary = assets[CoffeeV2PhotoSlot.cupSecondary]?.sha256;
    final saucer = assets[CoffeeV2PhotoSlot.saucer]?.sha256;
    if (primary != null && secondary != null && primary == secondary) {
      return CoffeeV2ValidationIssue.duplicatePrimarySecondary;
    }
    if (primary != null && saucer != null && primary == saucer) {
      return CoffeeV2ValidationIssue.duplicatePrimarySaucer;
    }
    if (secondary != null && saucer != null && secondary == saucer) {
      return CoffeeV2ValidationIssue.duplicateSecondarySaucer;
    }
    return null;
  }

  static CoffeeV2ValidationIssue? evaluate(CoffeeV2SubmissionRecord record) {
    final dup = duplicateIssue({
      for (final entry in record.slots.entries) entry.key: entry.value.asset,
    });
    if (dup != null) return dup;
    final allConfirmed = record.slots.values
        .every((slot) => slot.confirmed && slot.asset != null);
    if (!allConfirmed) return CoffeeV2ValidationIssue.incomplete;
    return null;
  }
}
