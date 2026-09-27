/// Fixed local owner for Dream service tests that do not exercise switching.
library;

import 'package:oracly_new/features/dream/services/dream_owner_guard.dart';

DreamOwnerGuard testDreamOwner([String ownerId = 'test-owner']) =>
    DreamOwnerGuard(ownerId: () => ownerId);
