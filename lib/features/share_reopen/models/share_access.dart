/// Decision after a share link — public by default.
library;

import '../models/share_ownership.dart';
import '../models/share_public_payload.dart';

class ShareAccess {
  const ShareAccess({
    required this.payload,
    required this.isOwner,
    required this.offerSignIn,
    this.localResultKey,
  });

  final SharePublicPayload payload;
  final bool isOwner;
  final bool offerSignIn;
  final String? localResultKey;

  static ShareAccess public(SharePublicPayload payload) {
    return ShareAccess(
      payload: payload,
      isOwner: false,
      offerSignIn: false,
    );
  }
}

class ShareAccessInput {
  const ShareAccessInput({
    required this.payload,
    this.sessionUserId,
    this.ownership,
  });

  final SharePublicPayload payload;
  final String? sessionUserId;
  final ShareOwnership? ownership;
}
