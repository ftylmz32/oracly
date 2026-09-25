/// Phase 7F — saved parser orientation L10n (no hardcoded Ters/Düz).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ReadingModel modelFor(String locale) {
    OraclyL10n.bind(locale);
    return ReadingModel(
      id: 'loc1',
      cardId: 17,
      cardName: 'The Star',
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      spreadType: 'single',
      // Unparseable as markdown sections → forces snapshot fallback body path
      // via empty cardsBody when cards present but parse succeeds/fails.
      aiSummary: 'plain text without sections',
      createdAt: DateTime.utc(2026, 9, 25),
      cards: const [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
          positionLabel: 'Present',
          isReversed: true,
        ),
      ],
    );
  }

  for (final locale in ['tr', 'en', 'ru']) {
    test('orientation localized for $locale — no hardcoded Ters/Düz prose', () {
      final model = modelFor(locale);
      final entry = ReadingHistoryMapper.fromModel(model);
      final content = SavedReadingParser.toContent(entry: entry, model: model);
      final body = content.cardReadings;
      expect(body, contains(TarotL10n.orientation(reversed: true)));
      expect(body.contains('konumunda'), isFalse);
      if (locale != 'tr') {
        expect(body.contains('Ters'), isFalse);
        expect(body.contains('Düz'), isFalse);
      }
    });
  }
}
