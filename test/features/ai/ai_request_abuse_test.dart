/// Abuse protection — duplicates, rate limits, no false positives.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_abuse_policy.dart';
import 'package:oracly_new/features/ai/production/ai_request_fingerprint.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';

void main() {
  late AiRequestGuard guard;

  setUp(() {
    guard = AiRequestGuard();
  });

  test('DUPLICATE — in-flight coalesce shares one Future', () async {
    var runs = 0;
    final first = guard.runOutcome<int>(
      'chat',
      () async {
        runs += 1;
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return AiOutcome.success(1);
      },
      kind: AiRequestKind.chat,
      fingerprint: 'chat:hi',
    );
    final second = guard.runOutcome<int>(
      'chat',
      () async {
        runs += 1;
        return AiOutcome.success(9);
      },
      kind: AiRequestKind.chat,
      fingerprint: 'chat:hi',
    );
    expect((await first).value, 1);
    expect((await second).value, 1);
    expect(runs, 1);
  });

  test('DUPLICATE — same fingerprint after success is blocked briefly', () async {
    var runs = 0;
    await guard.runOutcome<String>(
      'coffee',
      () async {
        runs += 1;
        return AiOutcome.success('ok');
      },
      kind: AiRequestKind.coffee,
      fingerprint: 'coffee:1',
    );
    final again = await guard.runOutcome<String>(
      'coffee',
      () async {
        runs += 1;
        return AiOutcome.success('again');
      },
      kind: AiRequestKind.coffee,
      fingerprint: 'coffee:1',
    );
    expect(again.failure?.kind, AiFailureKind.rateLimit);
    expect(runs, 1);
  });

  test('RATE LIMIT — burst of identical kind is capped', () async {
    var runs = 0;
    final limits = AiRequestAbusePolicy.of(AiRequestKind.soulmate);
    for (var i = 0; i < limits.burstMax; i++) {
      await guard.runOutcome<int>(
        'soulmate-$i',
        () async {
          runs += 1;
          return AiOutcome.success(i);
        },
        kind: AiRequestKind.soulmate,
        fingerprint: 'soulmate:$i',
      );
    }
    final blocked = await guard.runOutcome<int>(
      'soulmate-extra',
      () async {
        runs += 1;
        return AiOutcome.success(99);
      },
      kind: AiRequestKind.soulmate,
      fingerprint: 'soulmate:extra',
    );
    expect(blocked.failure?.kind, AiFailureKind.rateLimit);
    expect(runs, limits.burstMax);
  });

  test('NO FALSE POSITIVE — different fingerprints stay open', () async {
    var runs = 0;
    await guard.runOutcome<int>(
      'chat',
      () async {
        runs += 1;
        return AiOutcome.success(1);
      },
      kind: AiRequestKind.chat,
      fingerprint: 'chat:a',
    );
    final next = await guard.runOutcome<int>(
      'chat',
      () async {
        runs += 1;
        return AiOutcome.success(2);
      },
      kind: AiRequestKind.chat,
      fingerprint: 'chat:b',
    );
    expect(next.value, 2);
    expect(runs, 2);
  });

  test('NO FALSE POSITIVE — failure does not lock retry', () async {
    var runs = 0;
    await guard.runOutcome<int>(
      'dream',
      () async {
        runs += 1;
        return AiOutcome.failure(AiFailure.network());
      },
      kind: AiRequestKind.dream,
      fingerprint: 'dream:same',
    );
    final retry = await guard.runOutcome<int>(
      'dream',
      () async {
        runs += 1;
        return AiOutcome.success(3);
      },
      kind: AiRequestKind.dream,
      fingerprint: 'dream:same',
    );
    expect(retry.value, 3);
    expect(runs, 2);
  });

  test('idempotency key is stable for soulmate inputs', () {
    final a = AiRequestFingerprint.idempotencyKey(
      AiRequestFingerprint.soulMate(
        name: 'Ada',
        birthDate: '1994-03-12',
        gender: 'feminine',
        intention: 'sakin',
      ),
    );
    final b = AiRequestFingerprint.idempotencyKey(
      AiRequestFingerprint.soulMate(
        name: 'Ada',
        birthDate: '1994-03-12',
        gender: 'feminine',
        intention: 'sakin',
      ),
    );
    expect(a, b);
    expect(a.startsWith('or-'), isTrue);
  });
}
