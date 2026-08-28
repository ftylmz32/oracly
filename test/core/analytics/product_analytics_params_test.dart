import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/analytics/product_analytics_params.dart';

void main() {
  group('ProductAnalyticsParams', () {
    test('drops blocked keys and private-looking values', () {
      final safe = ProductAnalyticsParams.sanitize({
        'feature': 'tarot',
        'spread': 'three_card',
        'message': 'secret text',
        'userQuestion': 'will I win?',
        'success': true,
      });
      expect(safe['feature'], 'tarot');
      expect(safe['spread'], 'three_card');
      expect(safe['success'], true);
      expect(safe.containsKey('message'), isFalse);
      expect(safe.containsKey('userQuestion'), isFalse);
    });

    test('latency buckets are coarse', () {
      expect(
        ProductAnalyticsParams.latencyBucket(const Duration(milliseconds: 200)),
        'lt_500ms',
      );
      expect(
        ProductAnalyticsParams.latencyBucket(const Duration(seconds: 8)),
        '5s_15s',
      );
    });

    test('message length buckets never expose text', () {
      expect(ProductAnalyticsParams.messageLengthBucket(0), 'empty');
      expect(ProductAnalyticsParams.messageLengthBucket(12), 'short');
      expect(ProductAnalyticsParams.messageLengthBucket(400), 'long');
    });
  });
}
