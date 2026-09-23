import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_recall.dart';

void main() {
  group('TarotHistoricalRecall', () {
    test('TR / EN / RU detect; ordinary false', () {
      expect(TarotHistoricalRecall.detects('geçen falımı hatırla'), isTrue);
      expect(
        TarotHistoricalRecall.detects('remember my previous reading'),
        isTrue,
      );
      expect(
        TarotHistoricalRecall.detects('вспомнишь предыдущий расклад'),
        isTrue,
      );
      expect(
        TarotHistoricalRecall.detects('Should I leave this job quietly?'),
        isFalse,
      );
      expect(TarotHistoricalRecall.detects(null), isFalse);
    });
  });
}
