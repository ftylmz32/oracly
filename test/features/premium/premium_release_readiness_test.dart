/// P2 — Premium release readiness: honest store-closed architecture.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/features/premium/providers/premium_purchase_port_provider.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/core/notifications/memory_notification_port.dart';
import 'package:oracly_new/core/notifications/oracly_notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    return ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        oraclyNotificationPortProvider.overrideWithValue(
          MemoryNotificationPort(),
        ),
      ],
    );
  }

  test('default purchase port stays unconfigured until store products exist',
      () async {
    final c = await container();
    addTearDown(c.dispose);

    final port = c.read(premiumPurchasePortProvider);
    expect(port.isConfigured, isFalse);
    await port.prepare();
    expect(port.isConfigured, isFalse);

    final service = c.read(premiumServiceProvider);
    expect(service.purchaseConfigured, isFalse);
    expect(await service.isActive(), isFalse);

    final buy = await service.purchase(PremiumPlanKind.yearly);
    expect(buy.granted, isFalse);
    expect(await service.isActive(), isFalse);

    final restore = await service.restore();
    expect(restore.granted, isFalse);
  });

  test('home premium banner copy does not claim unlock-all', () {
    expect(PremiumCopy.homeBannerTitle.toLowerCase(), contains('premium'));
    expect(PremiumCopy.homeBannerBody.toLowerCase(), isNot(contains('kilid')));
    expect(PremiumCopy.homeBannerBody.toLowerCase(), isNot(contains('unlock')));
    expect(PremiumCopy.ctaUnavailable.toLowerCase(), contains('hen'));
    expect(PremiumCopy.planPricePending.toLowerCase(), contains('ma'));
  });

  test('tarot membership gate stays off; gems remain paid ritual cost', () {
    expect(TarotEconomy.requiresPremium(TarotSpreadType.threeCard), isFalse);
    expect(TarotEconomy.readingCost, 20);
  });
}
