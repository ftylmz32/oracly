/// Home premium discovery: no silent purchase, false offer or forced upsell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_premium_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_premium_cta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('store still loading: informative label, never a purchase promise', () {
    final state = HomeReferencePremiumCopy.resolveState(
      loaded: false,
      isPremium: false,
      busy: false,
      storeOffersPlans: false,
    );
    expect(state.body, PremiumCopy.loadingBody);
    expect(state.actionLabel, PremiumCopy.ctaInspect);
    expect(state.actionLabel, isNot(PremiumCopy.ctaJoin));
  });

  test('no store plans: unavailable status stays visible and honest', () {
    final state = HomeReferencePremiumCopy.resolveState(
      loaded: true,
      isPremium: false,
      busy: false,
      storeOffersPlans: false,
    );
    expect(state.body, PremiumCopy.ctaUnavailable);
    expect(state.actionLabel, PremiumCopy.ctaInspect);
    expect(state.actionLabel, isNot(PremiumCopy.ctaJoin));
  });

  test('confirmed store catalog: invite describes real premium benefits', () {
    final state = HomeReferencePremiumCopy.resolveState(
      loaded: true,
      isPremium: false,
      busy: false,
      storeOffersPlans: true,
    );
    expect(state.body, PremiumCopy.homeBannerBody);
    expect(state.actionLabel, PremiumCopy.homeInviteAction);
    expect(state.body, contains(PremiumCopy.benefitSoulmateTitle));
    expect(state.body, contains('Luna'));
    expect(state.body, isNot(contains('₺')));
  });

  test('pending state does not encourage a second purchase attempt', () {
    final state = HomeReferencePremiumCopy.resolveState(
      loaded: true,
      isPremium: false,
      busy: true,
      storeOffersPlans: true,
    );
    expect(state.body, PremiumCopy.ctaBusy);
    expect(state.actionLabel, PremiumCopy.ctaInspect);
  });

  test('held receipt says the purchase is being checked, never upsells',
      () {
    final state = HomeReferencePremiumCopy.resolveState(
      loaded: true,
      isPremium: false,
      busy: true,
      storeOffersPlans: true,
      awaitingVerdict: true,
    );
    expect(state.body, PremiumCopy.pendingVerifyTitle);
    expect(state.actionLabel, PremiumCopy.ctaInspect);
  });

  test('premium member sees their membership rather than upsell', () {
    final state = HomeReferencePremiumCopy.resolveState(
      loaded: true,
      isPremium: true,
      busy: false,
      storeOffersPlans: true,
    );
    expect(state.title, PremiumCopy.ctaActive);
    expect(state.actionLabel, PremiumCopy.homeMemberAction);
    expect(state.actionLabel, isNot(PremiumCopy.ctaJoin));
  });

  testWidgets('home invitation tap target is at least 44dp tall', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HomeReferencePremiumCta(
              label: PremiumCopy.homeInviteAction,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    final target = find.byType(HomeReferencePremiumCta);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    await tester.tap(target);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
