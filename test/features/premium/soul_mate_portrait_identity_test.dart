import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_interpretation_context.dart';
import 'package:oracly_new/features/premium/services/soul_mate_portrait_guard.dart';
import 'package:oracly_new/features/premium/services/soul_mate_portrait_identity.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('A same account keeps one core identity', () {
    final first = SoulMatePortraitIdentity.derive(
      accountKey: 'acct-a',
      presentation: 'feminine',
      renderNonce: 'one',
    );
    final second = SoulMatePortraitIdentity.derive(
      accountKey: 'acct-a',
      presentation: 'feminine',
      renderNonce: 'two',
    );
    expect(first.core.signature(), second.core.signature());
    expect(first.renderNonce, isNot(second.renderNonce));
  });

  test('B different accounts do not share a core profile', () {
    final a = SoulMatePortraitIdentity.derive(
      accountKey: 'acct-a',
      presentation: 'feminine',
    );
    final b = SoulMatePortraitIdentity.derive(
      accountKey: 'acct-b',
      presentation: 'feminine',
    );
    expect(a.core.signature(), isNot(b.core.signature()));
  });

  test('C four users stay distinct and deterministic', () {
    final ids = ['u1', 'u2', 'u3', 'u4'];
    final cores = [
      for (final id in ids)
        SoulMatePortraitIdentity.derive(
          accountKey: id,
          presentation: 'feminine',
        ).core.signature(),
    ];
    expect(cores.toSet(), hasLength(4));
    final again = [
      for (final id in ids)
        SoulMatePortraitIdentity.derive(
          accountKey: id,
          presentation: 'feminine',
        ).core.signature(),
    ];
    expect(again, cores);
  });

  test('E derived identity never carries a raw uid or email', () {
    final identity = SoulMatePortraitIdentity.derive(
      accountKey: 'firebase-uid-user-1',
      presentation: 'feminine',
    ).toIdentity();
    final raw = jsonEncode(identity.toJson());
    expect(raw, isNot(contains('firebase-uid-user-1')));
    expect(raw, isNot(contains('@')));
    expect(raw, isNot(contains('seed')));
  });

  test('F exact hash from another owner is rejected', () {
    const guard = SoulMatePortraitGuard();
    expect(
      guard.accepts(
        contentHash: 'abc',
        ownerId: 'owner-b',
        knownOwners: const {'abc': 'owner-a'},
      ),
      isFalse,
    );
  });

  test('G same owner may reopen its saved hash', () {
    const guard = SoulMatePortraitGuard();
    expect(
      guard.accepts(
        contentHash: 'abc',
        ownerId: 'owner-a',
        knownOwners: const {'abc': 'owner-a'},
      ),
      isTrue,
    );
  });

  test('I image budget stays locked at two', () {
    expect(SoulMatePortraitGuard.maxImageCalls, 2);
  });

  test('L legacy result without identity stays viewable', () {
    final saved = SoulMateSavedResult.fromJson({
      'id': 'legacy',
      'createdAt': '2024-01-01T00:00:00.000Z',
      'name': 'Ayse',
      'birthDate': '1994-03-12T00:00:00.000',
      'portraitPath': '/tmp/legacy.jpg',
      'parts': {
        'energy': '',
        'attraction': '',
        'dynamics': '',
        'feeling': '',
        'yourSide': '',
      },
    });
    expect(saved.identity, isNull);
    expect(saved.portraitPath, '/tmp/legacy.jpg');
    expect(saved.name, 'Ayse');
  });

  test('M portrait and interpretation share safe tone, not a face fact', () {
    final identity = SoulMatePortraitIdentity.derive(
      accountKey: 'acct-a',
      presentation: 'feminine',
    ).toIdentity();
    final context = SoulMateInterpretationContext.fromRequest(
      SoulMateDrawRequest(name: 'Ayse', birthDate: DateTime.utc(1994, 3, 12)),
      identity: identity,
    );
    expect(context.signature(), contains(identity.relationshipArchetype));
    expect(context.signature(), isNot(contains(identity.faceShape)));
  });

  test('J account switch does not inherit another portrait hash', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-a');
    final docs = await Directory.systemTemp.createTemp('soulmate-id');
    final service = SoulMateResultService(storage);
    final request = SoulMateDrawRequest(
      name: 'Ayse',
      birthDate: DateTime.utc(1994, 3, 12),
    );
    await service.saveSuccessfulDraw(
      request: request,
      imageBytes: [1, 2, 3],
      documents: docs,
      recordId: 'portrait-a',
      expectedOwnerId: 'owner-a',
      parts: const SoulMateReadingParts(
        energy: 'calm',
        attraction: 'quiet',
        dynamics: 'slow',
        feeling: 'steady',
        yourSide: 'patience',
        authoritative: true,
      ),
      identity: const SoulMateIdentity(
        nonce: 'render-a',
        presence: 'feminine-presenting adult',
        mood: 'reserved',
        faceShape: 'soft oval',
        relationshipArchetype: 'steady listener',
        contentHash: 'hash-a',
      ),
    );
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
    final stolen = await service.saveSuccessfulDraw(
      request: request,
      imageBytes: [9, 9, 9],
      documents: docs,
      recordId: 'portrait-b',
      expectedOwnerId: 'owner-b',
      identity: const SoulMateIdentity(
        nonce: 'render-b',
        presence: 'feminine-presenting adult',
        mood: 'reserved',
        contentHash: 'hash-a',
      ),
    );
    expect(stolen, isNull);
  });
}
