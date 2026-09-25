/// Phase 5E — typed input failures + importer / picker firewalls.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_choice.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_spread_screen.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_input.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_result.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_status.dart';

SignatureSpreadShadowCard _c({
  int ritual = 0,
  bool rev = false,
  int index = 0,
  String? key,
}) =>
    SignatureSpreadShadowCard(
      ritualCardId: ritual,
      isReversed: rev,
      positionIndex: index,
      positionKey: key,
    );

SignatureSpreadShadowResult _eval({
  required TarotSpreadType type,
  required List<SignatureSpreadShadowCard> cards,
  String sessionId = 's',
  String readingId = 'r',
  String lang = 'en',
  String? question,
}) =>
    SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: sessionId,
        readingId: readingId,
        languageCode: lang,
        spreadType: type,
        questionRaw: question,
        cards: cards,
      ),
    );

void main() {
  group('input red team', () {
    test('unsupported seven / celtic', () {
      expect(
        _eval(type: TarotSpreadType.sevenCard, cards: [_c()]).failureCode,
        SignatureShadowFailureCode.unsupportedRuntimeSpread,
      );
      expect(
        _eval(type: TarotSpreadType.celticCross, cards: [_c()]).failureCode,
        SignatureShadowFailureCode.unsupportedRuntimeSpread,
      );
    });

    test('card count / index failures', () {
      expect(
        _eval(type: TarotSpreadType.single, cards: []).failureCode,
        SignatureShadowFailureCode.cardCountMismatch,
      );
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c(), _c(index: 1)],
        ).failureCode,
        SignatureShadowFailureCode.cardCountMismatch,
      );
      expect(
        _eval(
          type: TarotSpreadType.threeCard,
          cards: [_c(), _c(index: 0, ritual: 1), _c(index: 2, ritual: 2)],
        ).failureCode,
        SignatureShadowFailureCode.duplicatePositionIndex,
      );
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c(index: -1)],
        ).failureCode,
        SignatureShadowFailureCode.negativePositionIndex,
      );
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c(index: 3)],
        ).failureCode,
        SignatureShadowFailureCode.outOfRangePositionIndex,
      );
      expect(
        _eval(
          type: TarotSpreadType.threeCard,
          cards: [_c(), _c(index: 2, ritual: 1)],
        ).failureCode,
        SignatureShadowFailureCode.cardCountMismatch,
      );
      expect(
        _eval(
          type: TarotSpreadType.threeCard,
          cards: [
            _c(),
            _c(index: 2, ritual: 1),
            _c(index: 3, ritual: 2),
          ],
        ).failureCode,
        SignatureShadowFailureCode.outOfRangePositionIndex,
      );
    });

    test('positionKey mismatch / reconstruct / invalid ritual', () {
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c(key: 'wrong')],
        ).failureCode,
        SignatureShadowFailureCode.positionKeyMismatch,
      );
      final ok = _eval(
        type: TarotSpreadType.single,
        cards: [_c(key: null)],
      );
      expect(ok.ok, isTrue);
      expect(ok.cards!.single.positionKey, 'sign');
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c(ritual: 999)],
        ).failureCode,
        SignatureShadowFailureCode.invalidRitualCardId,
      );
    });

    test('question kind rejects without silent remap', () {
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c()],
          question: 'Should I accept this offer?',
        ).failureCode,
        SignatureShadowFailureCode.unsupportedQuestionKind,
      );
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c()],
          question: 'How is this relationship evolving?',
        ).failureCode,
        SignatureShadowFailureCode.unsupportedQuestionKind,
      );
      expect(
        _eval(
          type: TarotSpreadType.crossroads,
          cards: [for (var i = 0; i < 5; i++) _c(ritual: i, index: i)],
          question: 'How is this relationship evolving?',
        ).failureCode,
        SignatureShadowFailureCode.unsupportedQuestionKind,
      );
    });

    test('empty identity + language normalize', () {
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c()],
          sessionId: '  ',
        ).failureCode,
        SignatureShadowFailureCode.emptySessionId,
      );
      expect(
        _eval(
          type: TarotSpreadType.single,
          cards: [_c()],
          readingId: '',
        ).failureCode,
        SignatureShadowFailureCode.emptyReadingId,
      );
      final r = _eval(
        type: TarotSpreadType.single,
        cards: [_c()],
        lang: 'Русский',
      );
      expect(r.languageCode, 'ru');
    });

    test('duplicate same card id — classical rejected by Phase 3', () {
      // Frozen NarrativeEvidenceValidation forbids duplicate canonical ids.
      final classical = _eval(
        type: TarotSpreadType.threeCard,
        cards: [
          _c(ritual: 0, index: 0),
          _c(ritual: 0, index: 1),
          _c(ritual: 0, index: 2),
        ],
      );
      expect(classical.ok, isFalse);
      expect(
        classical.failureCode,
        SignatureShadowFailureCode.evidenceBuildFailed,
      );
      expect(
        classical.phase3EvidenceStatus,
        SignaturePhase3EvidenceStatus.invalidInput,
      );

      // Phase 6G: Crossroads also goes through Phase 3 — duplicates fail closed.
      final crossroads = _eval(
        type: TarotSpreadType.crossroads,
        cards: [for (var i = 0; i < 5; i++) _c(ritual: 0, index: i)],
        question: 'Should I accept this offer?',
      );
      expect(crossroads.ok, isFalse);
      expect(
        crossroads.failureCode,
        SignatureShadowFailureCode.evidenceBuildFailed,
      );
      expect(
        crossroads.phase3EvidenceStatus,
        SignaturePhase3EvidenceStatus.invalidInput,
      );
    });
  });

  test('picker firewall still blocks Crossroads', () {
    final cr = SignatureSpreadCatalog.bySpreadId('signature.crossroads')!;
    expect(cr.offeredInLivePicker, isFalse);
    final entryTypes =
        TarotEntrySpreadChoice.offered().map((c) => c.type).toList();
    expect(entryTypes, isNot(contains(TarotSpreadType.crossroads)));
    expect(
      TarotRitualSpreadScreen.offeredSpreads,
      isNot(contains(TarotSpreadType.crossroads)),
    );
    expect(
      TarotTableSpreadOverlay.options,
      isNot(contains(TarotSpreadType.crossroads)),
    );
  });

  test('shadow evaluator has zero user-path production importers', () {
    final lib = Directory('lib');
    var hits = 0;
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      if (f.path.contains('signature_spreads')) continue;
      final src = f.readAsStringSync();
      if (src.contains('SignatureSpreadShadowEvaluator') ||
          src.contains('signature_spread_shadow_evaluator.dart')) {
        hits++;
      }
    }
    expect(hits, 0);
  });

  test('bridge still resolves ritual 0', () {
    expect(OraclyTarotBridge.byRitualId(0)?.id, 'major_00');
  });
}
