/// Phase 7F — ReadingModel provenance persistence + copyWith / JSON.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';

ReadingModel _base({
  String? resultMode,
  String? interpretationSource,
  String? deliveryKind,
}) =>
    ReadingModel(
      id: 'r1',
      cardId: 17,
      cardName: 'The Star',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      spreadType: 'threeCard',
      aiSummary: '## Summary\nCalm presence.',
      createdAt: DateTime.utc(2026, 9, 25),
      resultMode: resultMode,
      interpretationSource: interpretationSource,
      deliveryKind: deliveryKind,
      cards: const [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
          positionKey: 'present',
          isReversed: true,
        ),
      ],
    );

void main() {
  group('7F persistence metadata', () {
    test('resultMode / source / deliveryKind JSON roundtrip', () {
      final model = _base(
        resultMode: 'narrativeV2',
        interpretationSource: 'ai',
        deliveryKind: 'recovery',
      );
      final round = ReadingModel.fromJson(model.toJson());
      expect(round.resultMode, 'narrativeV2');
      expect(round.interpretationSource, 'ai');
      expect(round.deliveryKind, 'recovery');
      expect(round.cards.single.isReversed, isTrue);
      expect(round.cards.single.positionKey, 'present');
    });

    test('missing provenance fields remain null — backward compatible', () {
      final json = _base().toJson()
        ..remove('resultMode')
        ..remove('interpretationSource')
        ..remove('deliveryKind');
      final model = ReadingModel.fromJson(json);
      expect(model.resultMode, isNull);
      expect(model.interpretationSource, isNull);
      expect(model.deliveryKind, isNull);
    });

    test('copyWith note/favorite preserve provenance', () {
      final model = _base(
        resultMode: 'legacy',
        interpretationSource: 'local',
        deliveryKind: 'interpretation',
      );
      final noted = model.copyWith(
        journal: model.journal.copyWith(personalNote: 'quiet note'),
      );
      final fav = noted.copyWith(
        journal: noted.journal.copyWith(isFavorite: true),
      );
      expect(fav.resultMode, 'legacy');
      expect(fav.interpretationSource, 'local');
      expect(fav.deliveryKind, 'interpretation');
      expect(fav.cards.length, 1);
      expect(fav.aiSummary, model.aiSummary);
      expect(fav.personalNote, 'quiet note');
      expect(fav.isFavorite, isTrue);
    });

    test('remote-style toJson carries nullable keys when set', () {
      final json = _base(
        resultMode: 'narrativeV2',
        interpretationSource: 'ai',
        deliveryKind: 'interpretation',
      ).toJson();
      expect(json['resultMode'], 'narrativeV2');
      expect(json['interpretationSource'], 'ai');
      expect(json['deliveryKind'], 'interpretation');
    });
  });
}
