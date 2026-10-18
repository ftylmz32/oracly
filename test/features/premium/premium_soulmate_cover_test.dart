import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/premium/models/premium_models.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_experience_card.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved cover replaces only the premium soulmate plate', () {
    expect(
      PremiumReferenceExperienceCard.plateFor(PremiumBenefitAction.soulMate),
      AppAssets.premiumSoulMateCover,
    );
    expect(
      PremiumReferenceExperienceCard.aspectFor(PremiumBenefitAction.soulMate),
      1440 / 606,
    );
    expect(AppAssets.homeSoulMate, isNot(AppAssets.premiumSoulMateCover));
    expect(PremiumCopy.heroSubtitle, contains('beş'));
    expect(PremiumCopy.heroSubtitle.toLowerCase(), contains('ses'));
    expect(PremiumCopy.heroSubtitle.toLowerCase(), isNot(contains('tema')));
    expect(PremiumCopy.heroSubtitle.toLowerCase(), isNot(contains('arşiv')));
    expect(PremiumCopy.benefitJourneyBody, contains('gözlem'));
    expect(PremiumCopy.benefitContinuityBody.toLowerCase(), isNot(contains('arşiv')));
  });

  testWidgets('membership screen paints the approved cover, unstretched', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final plates = tester.widgetList<OraclyAssetImage>(
      find.byType(OraclyAssetImage),
    );
    final soulMate = plates.where(
      (image) => image.assetPath == AppAssets.premiumSoulMateCover,
    );
    expect(soulMate, hasLength(1));
    expect(soulMate.single.fit, BoxFit.cover);
    expect(soulMate.single.alignment, Alignment.center);
    expect(
      plates.map((image) => image.assetPath),
      isNot(contains(AppAssets.homeSoulMate)),
    );
    expect(tester.takeException(), isNull);
  });
}
