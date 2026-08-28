/// Owner check uses the local session + store, never URL parameters.
library;

import '../../../core/auth/models/auth_session.dart';
import '../models/share_access.dart';
import 'share_link_parser.dart';
import 'share_ownership_store.dart';

abstract final class ShareAccessResolver {
  ShareAccessResolver._();

  static ShareAccess? resolve(
    Uri uri, {
    required ShareOwnershipStore store,
    AuthSession? session,
  }) {
    final payload = ShareLinkParser.payloadOf(
      Uri(scheme: uri.scheme, host: uri.host, path: uri.path),
    );
    if (payload == null) return null;
    return decide(
      ShareAccessInput(
        payload: payload,
        sessionUserId: session?.userId,
        ownership: store.byId(payload.id),
      ),
    );
  }

  static ShareAccess decide(ShareAccessInput input) {
    final payload = input.payload;
    final owned = input.ownership;
    if (owned == null || owned.id != payload.id) {
      return ShareAccess.public(payload);
    }
    final uid = input.sessionUserId;
    if (uid == null || uid.isEmpty) {
      return ShareAccess(
        payload: payload,
        isOwner: false,
        offerSignIn: true,
      );
    }
    if (uid != owned.ownerUserId) {
      return ShareAccess.public(payload);
    }
    return ShareAccess(
      payload: payload,
      isOwner: true,
      offerSignIn: false,
      localResultKey: owned.localResultKey,
    );
  }
}
