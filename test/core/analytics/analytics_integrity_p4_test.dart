/// P4 analytics integrity — timing, privacy, no duplicate signals.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/analytics/product_analytics.dart';
import 'package:oracly_new/core/analytics/product_analytics_event.dart';
import 'package:oracly_new/core/analytics/product_analytics_params.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/monitoring/firebase_analytics.dart';
import 'package:oracly_new/core/services/analytics_service.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/economy/tarot_reading_charge.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSink implements FirebaseAnalyticsService {
  final events = <MapEntry<String, Map<String, Object?>?>>[];
  final screens = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  void setUserId(String? userId) {}

  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    events.add(MapEntry(name, params));
  }

  @override
  void logScreenView(String screenName) => screens.add(screenName);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingSink sink;
  late AnalyticsService analytics;

  setUp(() {
    sink = _RecordingSink();
    analytics = AnalyticsService(
      analytics: ProductAnalytics(sink: sink, isEnabled: () => true),
    );
  });

  test('sanitize never keeps message/question/note payloads', () {
    final safe = ProductAnalyticsParams.sanitize({
      'feature': 'or',
      'message': 'private thought',
      'question': 'will I succeed?',
      'note': 'journal note',
      'length_bucket': 'short',
    });
    expect(safe.keys.toList()..sort(), ['feature', 'length_bucket']);
  });

  test('OR message uses length_bucket not raw text', () {
    analytics.logOrMessageSent(length: 40);
    expect(sink.events.single.key, ProductAnalyticsEvent.orMessageSent);
    expect(sink.events.single.value?['length_bucket'], 'medium');
    expect(sink.events.single.value?.containsKey('source'), isFalse);
  });

  test('tarot gem success fires once after first paid commit', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final wallet = GemWalletService(GemWalletStore(storage));
    await wallet.earn(amount: 100, reason: 'seed');
    final charge = TarotReadingCharge(wallet, storage, analytics: analytics);
    expect(TarotEconomy.costFor(TarotSpreadType.threeCard), greaterThan(0));

    expect(await charge.commit('s1', spread: TarotSpreadType.threeCard), isTrue);
    expect(
      sink.events.where((e) => e.key == ProductAnalyticsEvent.gemPurchaseSuccess),
      hasLength(1),
    );

    expect(await charge.commit('s1', spread: TarotSpreadType.threeCard), isTrue);
    expect(
      sink.events.where((e) => e.key == ProductAnalyticsEvent.gemPurchaseSuccess),
      hasLength(1),
    );
  });

  test('feature_open is metadata only', () {
    analytics.logScreenView('or');
    expect(sink.screens, ['or']);
    expect(sink.events.single.key, ProductAnalyticsEvent.featureOpen);
    expect(sink.events.single.value?['feature'], 'or');
  });
}
