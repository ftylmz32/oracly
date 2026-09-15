/// Regression coverage for a real-device-confirmed bug: Coffee/Palm
/// analysis (`coffee_analysis`/`palm_analysis`) used the short default
/// client HTTP timeout (45s) meant for single-call chat/dream operations,
/// even though the server-side pipeline chains a vision "observer" call
/// and a text "writer" call — genuinely 60-90s+ under real load. Confirmed
/// live: a Palm analysis that completed successfully server-side at
/// ~62.5s was still marked `failed` client-side, because the old 45s
/// timeout fired first and the operation was already closed out as
/// failed by the time the real (successful) result arrived — the client
/// never observed a genuine completion.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/transport/ai_operation.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';

void main() {
  group('proxyAiClientTimeoutFor', () {
    const configTimeout = Duration(seconds: 45);
    const imageTimeout = Duration(seconds: 120);

    test(
        'THE BUG: coffee/palm analysis used to get the short chat timeout '
        '(45s) — too short for the real ~60-90s two-call pipeline', () {
      // This is the pre-fix behavior pinned as a named baseline: proves
      // the short timeout genuinely used to apply to these operations,
      // so a regression back to it is caught explicitly, not just by the
      // "long enough" assertions below happening to still pass.
      final chatTimeout = proxyAiClientTimeoutFor(
        AiOperation.chat,
        imageTimeout: imageTimeout,
        configTimeout: configTimeout,
      );
      expect(chatTimeout, configTimeout);
    });

    test(
        'THE FIX: coffee analysis gets the same long timeout treatment as '
        'soulmate draw, not the short chat timeout', () {
      final coffee = proxyAiClientTimeoutFor(
        AiOperation.coffeeAnalysis,
        imageTimeout: imageTimeout,
        configTimeout: configTimeout,
      );
      final soulmate = proxyAiClientTimeoutFor(
        AiOperation.soulmateDraw,
        imageTimeout: imageTimeout,
        configTimeout: configTimeout,
      );
      expect(coffee, soulmate);
      expect(coffee, greaterThan(const Duration(seconds: 90)));
      // Long enough to have covered the live-confirmed 62.5s Palm run
      // with real margin.
      expect(coffee, greaterThan(const Duration(seconds: 70)));
    });

    test('palm analysis gets the same long timeout treatment', () {
      final palm = proxyAiClientTimeoutFor(
        AiOperation.palmAnalysis,
        imageTimeout: imageTimeout,
        configTimeout: configTimeout,
      );
      expect(palm, greaterThan(const Duration(seconds: 70)));
    });

    test(
        'other single-call operations (chat/oracle/dream/tarot/tts) keep '
        'the short default timeout — this fix is scoped to the reading '
        'pipeline and soulmate only, not a blanket timeout increase', () {
      for (final op in [
        AiOperation.chat,
        AiOperation.oracle,
        AiOperation.dreamAnalysis,
        AiOperation.tarotReading,
        AiOperation.tts,
      ]) {
        final timeout = proxyAiClientTimeoutFor(
          op,
          imageTimeout: imageTimeout,
          configTimeout: configTimeout,
        );
        expect(timeout, configTimeout, reason: '${op.name} should be unaffected');
      }
    });

    test('stays well under the Cloud Run ceiling regardless of image timeout',
        () {
      final withMaxImageTimeout = proxyAiClientTimeoutFor(
        AiOperation.palmAnalysis,
        imageTimeout: const Duration(seconds: 180),
        configTimeout: configTimeout,
      );
      expect(withMaxImageTimeout, lessThan(const Duration(seconds: 176)));
    });
  });
}
