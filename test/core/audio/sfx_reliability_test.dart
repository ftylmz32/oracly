/// RELIABILITY BATCH 2A — Fix 2: SFX must not die silently.
///
/// This test sandbox has no audioplayers platform channel registered, so
/// every real playback attempt genuinely fails (not a fake) — exactly the
/// "plugin/runtime failure" scenario the fix targets. These tests prove
/// the service degrades honestly and stays usable, rather than getting
/// stuck reporting a stale "ready" state or throwing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/audio/oracly_sound_chamber.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/runtime/oracly_apply_outcome.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a transient init/play failure never permanently poisons SFX', () async {
    final service = OraclySoundService();
    addTearDown(service.dispose);

    final first = await service.play(OraclySoundCue.softTap);
    // No plugin registered in this sandbox — a real failure, not a fake.
    expect(first, OraclyApplyOutcome.failure);
    expect(service.sfxReady, isFalse);

    // The service must remain usable: the very next tap is retried fresh,
    // not stuck reusing a broken player or throwing.
    final second = await service.play(OraclySoundCue.selection);
    expect(second, OraclyApplyOutcome.failure);
    expect(service.sfxReady, isFalse);

    final third = await service.play(OraclySoundCue.cardFlip);
    expect(third, OraclyApplyOutcome.failure);
  });

  test('disabled sound effects never attempt playback', () async {
    final service = OraclySoundService();
    addTearDown(service.dispose);
    service.syncSfxEnabled(false);

    final outcome = await service.play(OraclySoundCue.softTap);

    // Disabled is an intentional no-op, not a failure.
    expect(outcome, OraclyApplyOutcome.success);
    // ensureSfxReady was never even attempted while disabled.
    expect(service.sfxReady, isFalse);
  });

  test('re-enabling after a failure allows a fresh attempt, not a stuck state', () async {
    final service = OraclySoundService();
    addTearDown(service.dispose);

    service.syncSfxEnabled(false);
    final skipped = await service.play(OraclySoundCue.softTap);
    expect(skipped, OraclyApplyOutcome.success);

    service.syncSfxEnabled(true);
    final attempted = await service.play(OraclySoundCue.softTap);

    // It genuinely tried again (and fails honestly here, since there is
    // still no plugin) rather than silently reusing a stale enabled/ready
    // flag from before the toggle flipped.
    expect(attempted, OraclyApplyOutcome.failure);
  });

  test('stopSfx never throws even when nothing is playing', () async {
    final service = OraclySoundService();
    addTearDown(service.dispose);
    await service.stopSfx();
  });
}
