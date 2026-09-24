/// Phase 6B.1 — Signature history normalizer: no broad catch / invariant visible.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_card_normalize.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_history_spread_normalizer.dart';

void main() {
  group('SignatureHistorySpreadNormalizer', () {
    test('Crossroads resolves exact projected identity', () {
      final s = SignatureHistorySpreadNormalizer.fromSpread(
        TarotSpreadType.crossroads,
      );
      expect(s, isNotNull);
      expect(s!.spreadId, 'signature.crossroads');
      expect(s.legacyTypeName, 'crossroads');
      expect(s.cardCount, 5);
      expect(
        s.positions.map((p) => p.positionKey).toList(),
        ['option_a', 'option_b', 'tension', 'counsel', 'direction'],
      );
    });

    test('Classical runtime types return null — no throw', () {
      for (final type in [
        TarotSpreadType.single,
        TarotSpreadType.threeCard,
        TarotSpreadType.fiveCard,
        TarotSpreadType.sevenCard,
        TarotSpreadType.celticCross,
      ]) {
        expect(
          SignatureHistorySpreadNormalizer.fromSpread(type),
          isNull,
          reason: type.name,
        );
      }
    });

    test('unknown persisted spread still fails closed as null', () {
      expect(
        TarotHistoryCardNormalize.supportedFromPersisted('garbage_spread_xyz'),
        isNull,
      );
      expect(
        () => TarotHistoryCardNormalize.supportedFromPersisted(
          'garbage_spread_xyz',
        ),
        returnsNormally,
      );
    });

    test('source has no broad catch around Signature resolution', () {
      final src = File(
        'lib/features/tarot/signature_spreads/'
        'signature_history_spread_normalizer.dart',
      ).readAsStringSync();
      expect(src.contains('catch (_)'), isFalse);
      expect(src.contains('catch (Object'), isFalse);
      expect(src.contains('catch (Exception'), isFalse);
      expect(src.contains('catch ('), isFalse);
    });
  });
}
