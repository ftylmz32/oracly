/// Share reopen — public payload, owner from session+store, never URL auth.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/auth/models/auth_session.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/discovery_share/copy/discovery_share_copy.dart';
import 'package:oracly_new/features/discovery_share/models/shareable_discovery.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_builder.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_controller.dart';
import 'package:oracly_new/features/discovery_share/services/discovery_share_port.dart';
import 'package:oracly_new/features/share_reopen/models/share_ownership.dart';
import 'package:oracly_new/features/share_reopen/models/share_public_payload.dart';
import 'package:oracly_new/features/share_reopen/services/share_access_resolver.dart';
import 'package:oracly_new/features/share_reopen/services/share_feature_routes.dart';
import 'package:oracly_new/features/share_reopen/services/share_link_parser.dart';
import 'package:oracly_new/features/share_reopen/services/share_ownership_store.dart';
import 'package:oracly_new/features/share_reopen/services/share_payload_codec.dart';
import 'package:oracly_new/features/share_reopen/services/share_reference_issuer.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../discovery_share/discovery_share_fakes.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  AuthSession owner() => AuthSession(
        userId: 'owner-1',
        provider: AuthProviderKind.email,
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

  test('link encodes public card only and reopens the feature', () {
    final payload = SharePublicPayload(
      id: 'ab12cd34ef56ab78',
      kind: DiscoveryShareKind.tarot,
      highlight: 'Denge',
    );
    final uri = ShareLinkParser.build(payload);
    expect(uri.scheme, 'oracly');
    expect(uri.host, 'share');
    expect(uri.query, isEmpty);
    final parsed = ShareLinkParser.parse(
      '$uri?owner=true&userId=owner-1&readingId=private-99',
    );
    expect(parsed, isNotNull);
    expect(parsed!.query, isEmpty);
    final restored = ShareLinkParser.payloadOf(parsed)!;
    expect(restored.kind, DiscoveryShareKind.tarot);
    expect(restored.highlight, 'Denge');
    expect(restored.toPublicJson().keys, SharePublicPayload.allowedKeys);
    expect(
      ShareFeatureRoutes.publicRoute(restored.kind),
      OraclyRoutes.tarot,
    );
  });

  test('auth never trusts URL parameters', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ShareOwnershipStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final payload = SharePublicPayload(
      id: 'ab12cd34ef56ab78',
      kind: DiscoveryShareKind.coffee,
      highlight: 'Değişim',
    );
    await store.put(
      ShareOwnership(
        id: payload.id,
        ownerUserId: 'owner-1',
        localResultKey: 'local-cup',
      ),
    );
    final forged = ShareLinkParser.build(payload).replace(
      queryParameters: {
        'owner': 'true',
        'userId': 'owner-1',
        'readingId': 'stolen',
        'token': 'Bearer abc',
      },
    );
    final guest = ShareAccessResolver.resolve(forged, store: store);
    expect(guest!.isOwner, isFalse);
    expect(guest.offerSignIn, isTrue);
    expect(guest.localResultKey, isNull);
    final stranger = ShareAccessResolver.resolve(
      forged,
      store: store,
      session: AuthSession(
        userId: 'stranger-9',
        provider: AuthProviderKind.email,
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    expect(stranger!.isOwner, isFalse);
    expect(stranger.localResultKey, isNull);
    final mine = ShareAccessResolver.resolve(
      forged,
      store: store,
      session: owner(),
    );
    expect(mine!.isOwner, isTrue);
    expect(mine.localResultKey, 'local-cup');
    expect(mine.localResultKey, isNot('stolen'));
    expect(
      ShareFeatureRoutes.ownerRoute(DiscoveryShareKind.tarot),
      OraclyRoutes.readingHistory,
    );
  });

  test('privacy: extra JSON and private phrases never ride the link', () async {
    final dirty = jsonEncode({
      'i': 'ab12cd34ef56ab78',
      'k': 'coffee',
      'h': 'user_id 4491 and 1994-03-12 ayse@mail.com',
      'ownerUserId': 'owner-1',
      'readingId': 'private-dream',
      'text': 'I dreamed of my mother',
    });
    final token = base64Url.encode(utf8.encode(dirty)).replaceAll('=', '');
    final payload = SharePayloadCodec.decode(token)!;
    expect(payload.highlight, DiscoveryShareCopy.fallbackHighlight);
    expect(payload.toPublicJson().containsKey('text'), isFalse);
    expect(payload.toPublicJson().containsKey('ownerUserId'), isFalse);
    SharedPreferences.setMockInitialValues({});
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(owner());
    final issuer = ShareReferenceIssuer(
      store: ShareOwnershipStore(
        LocalStorage(await SharedPreferences.getInstance()),
      ),
      sessions: sessions,
      random: Random(1),
    );
    final card = DiscoveryShareBuilder.tarot(
      theme: 'Denge',
      cardName: 'Ayşe sorusu: işimi bırakmalı mıyım?',
    );
    final port = RecordingDiscoveryShare();
    await DiscoveryShareController(
      port: port,
      renderer: const SilentDiscoveryShareCard(),
      references: issuer,
    ).share(card);
    expect(port.last!.caption, contains('oracly://share/'));
    expect(port.last!.caption, isNot(contains('Ayşe')));
    expect(port.last!.caption, isNot(contains('bırakmalı')));
    expect(port.last!.caption.toLowerCase(), isNot(contains('owneruserid')));
  });

  test('canceled share does not bind ownership', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = ShareOwnershipStore(storage);
    final sessions = InMemorySessionManager(_MemTokens());
    await sessions.setSession(owner());
    final issuer = ShareReferenceIssuer(
      store: store,
      sessions: sessions,
      random: Random(2),
    );
    final port = RecordingDiscoveryShare()
      ..next = DiscoveryShareOutcome.canceled;
    await DiscoveryShareController(
      port: port,
      renderer: const SilentDiscoveryShareCard(),
      references: issuer,
    ).share(DiscoveryShareBuilder.tarot(theme: 'Denge'));
    expect(store.all(), isEmpty);
  });
}

class _MemTokens implements TokenManager {
  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => 'a';

  @override
  Future<String?> getRefreshToken() async => 'r';

  @override
  Future<bool> hasValidAccessToken() async => true;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {}
}
