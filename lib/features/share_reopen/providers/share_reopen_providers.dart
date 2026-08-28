/// Riverpod wiring for share reopen.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/backend_providers.dart';
import '../services/share_ownership_store.dart';
import '../services/share_reference_issuer.dart';

final shareOwnershipStoreProvider = Provider<ShareOwnershipStore>((ref) {
  return ShareOwnershipStore(ref.watch(localStorageProvider));
});

final shareReferenceIssuerProvider = Provider<ShareReferenceIssuer>((ref) {
  return ShareReferenceIssuer(
    store: ref.watch(shareOwnershipStoreProvider),
    sessions: ref.watch(sessionManagerProvider),
  );
});
