/// Phase 5D — runtime enum, persistence, picker firewall, dual-read.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/spread_engine.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_session_recovery.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_entry/tarot_entry_spread_choice.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_spread_screen.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_runtime_bridge.dart';
import 'package:oracly_new/features/tarot/signature_spreads/tarot_position_key_compat.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('enum regression', () {
    test('order and indices frozen', () {
      expect(
        TarotSpreadType.values.map((e) => e.name).toList(),
        [
          'single',
          'threeCard',
          'fiveCard',
          'sevenCard',
          'celticCross',
          'crossroads',
        ],
      );
      expect(TarotSpreadType.single.index, 0);
      expect(TarotSpreadType.threeCard.index, 1);
      expect(TarotSpreadType.fiveCard.index, 2);
      expect(TarotSpreadType.sevenCard.index, 3);
      expect(TarotSpreadType.celticCross.index, 4);
      expect(TarotSpreadType.crossroads.index, 5);
      expect(TarotSpreadType.crossroads.cardCount, 5);
    });
  });

  group('persisted parser dual-read', () {
    test('machine ids + legacy titles + crossroads', () {
      expect(TarotSpreadType.fromPersisted(null), isNull);
      expect(TarotSpreadType.fromPersisted(''), isNull);
      expect(TarotSpreadType.fromPersisted('unknown_xyz'), isNull);
      expect(TarotSpreadType.fromPersisted('single'), TarotSpreadType.single);
      expect(TarotSpreadType.fromPersisted('threeCard'), TarotSpreadType.threeCard);
      expect(TarotSpreadType.fromPersisted('crossroads'), TarotSpreadType.crossroads);
      expect(TarotSpreadType.fromPersisted('Tek Kart'), TarotSpreadType.single);
      expect(TarotSpreadType.fromPersisted('Üç Kart'), TarotSpreadType.threeCard);
      expect(TarotSpreadType.fromPersisted('Derin Açılım'), TarotSpreadType.fiveCard);
      expect(TarotSpreadType.fromPersisted('Yedi Kart'), TarotSpreadType.sevenCard);
      expect(TarotSpreadType.fromPersisted('Kelt Haçı'), TarotSpreadType.celticCross);
      expect(TarotSpreadType.fromPersisted('One Card'), TarotSpreadType.single);
      expect(TarotSpreadType.fromPersisted('Three Cards'), TarotSpreadType.threeCard);
      expect(TarotSpreadType.fromPersisted('Deep Spread'), TarotSpreadType.fiveCard);
      expect(TarotSpreadType.fromPersisted('Yol Ayrımı'), TarotSpreadType.crossroads);
      expect(TarotSpreadType.fromPersisted('Crossroads'), TarotSpreadType.crossroads);
      expect(TarotSpreadType.fromPersisted('Перекрёсток'), TarotSpreadType.crossroads);
    });
  });

  group('Crossroads runtime + signature parity', () {
    test('positions and interpretation order', () {
      final def = SpreadEngine.of(TarotSpreadType.crossroads);
      expect(def.cardCount, 5);
      expect(
        def.positions.map((p) => p.key).toList(),
        ['option_a', 'option_b', 'tension', 'counsel', 'direction'],
      );
      expect(def.interpretationOrder, [0, 1, 2, 3, 4]);
      final sig = SignatureSpreadCatalog.bySpreadId('signature.crossroads')!;
      expect(
        def.positions.map((p) => p.key).toList(),
        sig.positions.map((p) => p.positionKey).toList(),
      );
      expect(def.interpretationOrder, sig.interpretationOrder);
    });

    test('runtime bridge launch only', () {
      expect(SignatureSpreadRuntimeBridge.launchRuntimeTypes, hasLength(4));
      expect(
        SignatureSpreadRuntimeBridge.definitionFor(TarotSpreadType.single)
            ?.spreadId,
        'classical.single',
      );
      expect(
        SignatureSpreadRuntimeBridge.definitionFor(TarotSpreadType.crossroads)
            ?.spreadId,
        'signature.crossroads',
      );
      expect(
        SignatureSpreadRuntimeBridge.definitionFor(TarotSpreadType.sevenCard),
        isNull,
      );
      expect(
        SignatureSpreadRuntimeBridge.definitionFor(TarotSpreadType.celticCross),
        isNull,
      );
    });
  });

  group('session roundtrips', () {
    ReadingSession base(TarotSpreadType spread) => ReadingSession(
          id: 'sid-${spread.name}',
          deckId: 'classic',
          spread: spread,
          intention: const TarotIntention(text: 'q'),
          shuffleSeed: 1,
          startedAt: DateTime(2026, 9, 1),
          drawnCards: const [],
        );

    test('old sessions restore by machine name', () {
      for (final s in [
        TarotSpreadType.single,
        TarotSpreadType.threeCard,
        TarotSpreadType.fiveCard,
        TarotSpreadType.sevenCard,
        TarotSpreadType.celticCross,
      ]) {
        final json = base(s).toJson();
        expect(json['spread'], s.name);
        final restored = ReadingSession.tryFromJson(json);
        expect(restored?.spread, s);
      }
    });

    test('Crossroads session roundtrip', () {
      final session = base(TarotSpreadType.crossroads);
      expect(session.toJson()['spread'], 'crossroads');
      final raw = jsonEncode(session.toJson());
      final recovered = TarotSessionRecovery.decode(raw);
      expect(recovered?.spread, TarotSpreadType.crossroads);
      expect(recovered?.requiredCardCount, 5);
    });

    test('unknown session spread fails closed', () {
      final json = base(TarotSpreadType.single).toJson();
      json['spread'] = 'notARealSpread';
      expect(ReadingSession.tryFromJson(json), isNull);
      expect(
        TarotSessionRecovery.decode(jsonEncode(json)),
        isNull,
      );
    });
  });

  group('history write + display', () {
    late ReadingService readings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      readings = ReadingService(
        MockHistoryRepository(storage),
        MockUserRepository(storage),
      );
    });

    Future<ReadingModel> save(TarotSpreadType spread) async {
      final card = CardRevealSpread.forIndex(0).card;
      final pos = SpreadEngine.positionAt(spread, 0)!;
      final saved = await readings.saveFromSession(
        session: ReadingSession(
          id: 'h-${spread.name}',
          deckId: 'classic',
          spread: spread,
          intention: const TarotIntention(text: 'reflect'),
          shuffleSeed: 2,
          startedAt: DateTime(2026, 9, 2),
          drawnCards: [
            TarotDrawnCard(
              card: card,
              positionIndex: 0,
              positionLabel: pos.label,
              positionKey: pos.key,
              isReversed: false,
            ),
          ],
        ),
        aiSummary: 'Quiet reflection.',
      );
      return saved!;
    }

    test('new writes persist machine id locale-independently', () async {
      OraclyL10n.bind('tr');
      final a = await save(TarotSpreadType.threeCard);
      expect(a.spreadType, 'threeCard');
      OraclyL10n.bind('en');
      final b = await save(TarotSpreadType.fiveCard);
      expect(b.spreadType, 'fiveCard');
      OraclyL10n.bind('ru');
      final c = await save(TarotSpreadType.crossroads);
      expect(c.spreadType, 'crossroads');
      expect(c.cards.single.positionKey, 'option_a');
      OraclyL10n.bind('tr');
    });

    test('display resolves machine id and legacy titles', () {
      OraclyL10n.bind('tr');
      expect(TarotL10n.spreadFromStorage('threeCard'), 'Üç Kart');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Yol Ayrımı');
      OraclyL10n.bind('en');
      expect(TarotL10n.spreadFromStorage('threeCard'), 'Three Cards');
      expect(TarotL10n.spreadFromStorage('Crossroads'), 'Crossroads');
      OraclyL10n.bind('ru');
      expect(TarotL10n.spreadFromStorage('threeCard'), 'Три карты');
      OraclyL10n.bind('tr');
    });
  });

  group('positionKey reconstruction', () {
    test('legacy and machine reconstruction', () {
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'Three Cards',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 0,
          ),
        ),
        'past',
      );
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'Üç Kart',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 2,
          ),
        ),
        'future',
      );
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'fiveCard',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 1,
          ),
        ),
        'hidden_influence',
      );
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'crossroads',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 0,
          ),
        ),
        'option_a',
      );
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'crossroads',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 3,
          ),
        ),
        'counsel',
      );
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'crossroads',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 5,
          ),
        ),
        isNull,
      );
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: 'ghost',
          snapshot: const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'a',
            cardImageAsset: 'x',
            positionIndex: 0,
          ),
        ),
        isNull,
      );
    });
  });

  group('picker firewall', () {
    test('Crossroads never offered', () {
      final entryTypes =
          TarotEntrySpreadChoice.offered().map((c) => c.type).toList();
      expect(entryTypes, isNot(contains(TarotSpreadType.crossroads)));
      expect(entryTypes, contains(TarotSpreadType.single));
      expect(entryTypes, contains(TarotSpreadType.threeCard));
      expect(entryTypes, contains(TarotSpreadType.fiveCard));

      expect(
        TarotRitualSpreadScreen.offeredSpreads,
        [TarotSpreadType.single, TarotSpreadType.threeCard, TarotSpreadType.fiveCard],
      );
      expect(
        TarotTableSpreadOverlay.options,
        [TarotSpreadType.single, TarotSpreadType.threeCard, TarotSpreadType.fiveCard],
      );
      expect(
        TarotTableSpreadOverlay.options,
        isNot(contains(TarotSpreadType.crossroads)),
      );
    });
  });

  group('legacy reopen', () {
    test('legacy ReadingModel preserves summary and reconstructs key', () {
      final model = ReadingModel(
        id: 'legacy1',
        cardId: 0,
        cardName: 'The Fool',
        cardImageAsset: 'a',
        spreadType: 'Üç Kart',
        aiSummary: 'Stored reflection stays.',
        createdAt: DateTime(2026, 1, 1),
        cards: const [
          ReadingCardSnapshot(
            cardId: 0,
            cardName: 'The Fool',
            cardImageAsset: 'a',
            positionIndex: 1,
            positionLabel: 'Şimdi',
          ),
        ],
      );
      expect(model.aiSummary, 'Stored reflection stays.');
      expect(model.cards.single.cardName, 'The Fool');
      expect(TarotSpreadType.fromPersisted(model.spreadType), TarotSpreadType.threeCard);
      expect(
        TarotPositionKeyCompat.resolve(
          persistedSpread: model.spreadType,
          snapshot: model.cards.single,
        ),
        'present',
      );
      OraclyL10n.bind('en');
      expect(TarotL10n.spreadFromStorage(model.spreadType), 'Three Cards');
      OraclyL10n.bind('tr');
      expect(TarotL10n.spreadFromStorage(model.spreadType), 'Üç Kart');
    });
  });
}
