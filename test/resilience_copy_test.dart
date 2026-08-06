import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/services/ai_message_result.dart';

void main() {
  group('ResilienceCopy', () {
    test('error copy avoids technical language', () {
      expect(ResilienceCopy.errorTitle.toLowerCase(), isNot(contains('hata')));
      expect(ResilienceCopy.aiUnavailable.toLowerCase(), isNot(contains('api')));
      expect(ResilienceCopy.aiUnavailable.toLowerCase(), isNot(contains('500')));
      expect(ResilienceCopy.offline.toLowerCase(), contains('bağlantı'));
    });

    test('empty states guide without pressure', () {
      expect(ResilienceCopy.memoryEmptyBody.toLowerCase(), contains('silebilirsin'));
      expect(ResilienceCopy.chatHistoryEmptyBody.toLowerCase(), isNot(contains('hemen')));
    });

    test('retry action is consistent', () {
      expect(ResilienceCopy.retryAction, 'Tekrar Dene');
    });
  });

  group('AiMessageResult', () {
    test('success requires non-empty content', () {
      expect(const AiMessageResult.success('Merhaba.').isSuccess, isTrue);
      expect(const AiMessageResult.success('  ').isSuccess, isFalse);
    });

    test('failure carries user message not technical detail', () {
      const result = AiMessageResult.failure(ResilienceCopy.offline);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, ResilienceCopy.offline);
    });
  });
}
