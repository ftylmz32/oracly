/// Mints a public-safe share URI; binds owner only after share completes.
library;

import 'dart:math';

import '../../../core/auth/session_manager.dart';
import '../../discovery_share/models/shareable_discovery.dart';
import '../../discovery_share/services/discovery_share_sanitize.dart';
import '../models/share_ownership.dart';
import '../models/share_public_payload.dart';
import 'issued_share_reference.dart';
import 'share_link_parser.dart';
import 'share_ownership_store.dart';

class ShareReferenceIssuer {
  ShareReferenceIssuer({
    required this.store,
    this.sessions,
    Random? random,
  }) : _random = random ?? Random.secure();

  final ShareOwnershipStore store;
  final SessionManager? sessions;
  final Random _random;

  Future<IssuedShareReference> issue(
    ShareableDiscovery discovery, {
    String? localResultKey,
  }) async {
    final highlight = DiscoveryShareSanitize.highlight(discovery.highlight);
    final payload = SharePublicPayload(
      id: _id(),
      kind: discovery.kind,
      highlight: highlight,
    );
    return IssuedShareReference(
      id: payload.id,
      uri: ShareLinkParser.build(payload),
      localResultKey: localResultKey,
    );
  }

  Future<void> bind(IssuedShareReference issued) async {
    final owner = sessions?.currentSession?.userId;
    if (owner == null || owner.isEmpty) return;
    await store.put(
      ShareOwnership(
        id: issued.id,
        ownerUserId: owner,
        localResultKey: issued.localResultKey,
      ),
    );
  }

  String _id() {
    final bytes = List<int>.generate(8, (_) => _random.nextInt(256));
    return [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
  }
}
