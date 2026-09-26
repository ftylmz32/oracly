/// Phase 8B.1 — one prepared live transaction (owner snapshot + plan).
library;

import 'package:flutter/foundation.dart';

import 'yildizname_live_owner_snapshot.dart';
import 'yildizname_live_plan.dart';

/// Binds the owner/epoch captured at preparation to the exact local plan.
///
/// Never holds provider output, BuildContext or Riverpod refs. Execution
/// rechecks this snapshot — it never recaptures a new owner as authority.
@immutable
final class YildiznamePreparedLiveExecution {
  const YildiznamePreparedLiveExecution({
    required this.ownerSnapshot,
    required this.languageCode,
    required this.plan,
  });

  final YildiznameLiveOwnerSnapshot ownerSnapshot;
  final String languageCode;
  final YildiznameLivePlan plan;

  bool get isLegacy => plan.kind == YildiznameLivePlanKind.legacyLocal;
}
