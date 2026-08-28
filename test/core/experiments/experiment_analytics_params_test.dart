import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/analytics/product_analytics_params.dart';

void main() {
  test('experiment analytics params stay metadata-only', () {
    final safe = ProductAnalyticsParams.sanitize({
      'experiment': 'coffee_cta_copy',
      'variant': 'open_cup',
      'feature': 'coffee',
      'message': 'Falımı Yorumla',
      'text': 'secret',
    });
    expect(safe['experiment'], 'coffee_cta_copy');
    expect(safe['variant'], 'open_cup');
    expect(safe['feature'], 'coffee');
    expect(safe.containsKey('message'), isFalse);
    expect(safe.containsKey('text'), isFalse);
  });
}
