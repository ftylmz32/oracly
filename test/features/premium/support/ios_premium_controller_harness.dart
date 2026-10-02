/// Real controller + service over a [FakeStoreKit], loaded once.
library;

import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/features/premium/controllers/premium_status_controller.dart';
import 'package:oracly_new/features/premium/services/store_premium_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ios_storekit_fake.dart';

Future<(PremiumStatusController, PremiumService)> loadedIosPremium(
  FakeStoreKit iap,
) async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final service = PremiumService(
    MockPremiumRepository(storage),
    MockUserRepository(storage),
    StorePremiumPurchase(client: iap),
    ActiveVerifier(),
  )..forceReleaseMode = true;
  final status = PremiumStatusController(service);
  await status.load();
  return (status, service);
}
