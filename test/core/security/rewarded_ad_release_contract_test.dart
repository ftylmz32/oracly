import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rewarded Ads release contract.
///
/// Replaces the older `ad_free_release_contract_test.dart`, which encoded
/// a pre-rewarded-ads product policy ("no rewarded-ad code may exist at
/// all"). That policy is obsolete: rewarded ads are now an intentional
/// ORACLY capability. This test verifies the *safety* contract around
/// them instead of asserting their absence -- see ARCHITECT DECISION 2
/// (canonical reconciliation finalization) for the policy this encodes:
///   - no forced/interstitial/banner ad path
///   - explicitly user-initiated only
///   - dormant/no-op without real ad-provider configuration
///   - server-authoritative reward verification (never client-fabricated)
void main() {
  group('Rewarded Ads release contract', () {
    test('no forced/interstitial/banner ad integration exists', () {
      const roots = <String>['lib', 'android'];
      const textExtensions = <String>{
        '.dart',
        '.gradle',
        '.java',
        '.json',
        '.kt',
        '.kts',
        '.properties',
        '.xml',
        '.yaml',
        '.yml',
      };
      final runtimeFiles = <File>[
        for (final root in roots)
          ...Directory(root)
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (file) => textExtensions.any(file.path.toLowerCase().endsWith),
              ),
        File('pubspec.yaml'),
        File('pubspec.lock'),
      ];
      final runtime = runtimeFiles
          .map((file) => file.readAsStringSync())
          .join('\n')
          .toLowerCase();

      // Forbidden regardless of rewarded-ad policy: nothing may force an
      // ad in front of a reading, and no banner/interstitial/app-open ad
      // surface may be wired in anywhere -- only the explicitly
      // user-initiated rewarded-ad flow is permitted.
      for (final forbidden in <String>[
        'interstitialad',
        'bannerad',
        'appopenad',
        'admanagerinterstitial',
        'admanagerbanner',
      ]) {
        expect(runtime, isNot(contains(forbidden)), reason: forbidden);
      }
    });

    test(
      'rewarded-ad provider is dormant/no-op without explicit configuration',
      () {
        // Current shipped state: no concrete ad SDK dependency is
        // compiled in, so rewardedAdProvider must resolve to null and the
        // card must collapse -- this is what keeps the capability
        // dormant until a real provider is intentionally enabled.
        final pubspecLock = File('pubspec.lock').readAsStringSync().toLowerCase();
        expect(pubspecLock, isNot(contains('google_mobile_ads')));

        final providerSource = File(
          'lib/features/gems/providers/gem_providers.dart',
        ).readAsStringSync();
        expect(
          providerSource,
          contains('return null;'),
          reason:
              'rewardedAdProvider must stay a no-op until a real ad SDK/provider is intentionally wired in',
        );
      },
    );

    test(
      'gem card hides the rewarded-ad entry point when the provider is null or the user is Premium',
      () {
        final cardSource = File(
          'lib/features/gems/presentation/reference/gems_rewarded_ad_card.dart',
        ).readAsStringSync();
        expect(cardSource, contains('isPremium'));
        expect(cardSource, contains('SizedBox.shrink()'));
      },
    );

    test(
      'the on-screen rewarded-ad control requires an explicit user tap, never auto-triggers',
      () {
        final cardSource = File(
          'lib/features/gems/presentation/reference/gems_rewarded_ad_card.dart',
        ).readAsStringSync();
        // A FilledButton onPressed callback is the only way `service.show`
        // or `service.load` can run from this widget -- there is no
        // initState/build-time auto-invocation anywhere in the card.
        expect(cardSource, contains('onPressed:'));
        expect(cardSource, isNot(contains('initState')));
      },
    );

    test(
      'gem reward requires server-side balance confirmation, not a client-reported flag',
      () {
        final serviceSource = File(
          'lib/features/gems/services/rewarded_ad_service.dart',
        ).readAsStringSync();
        // The client never credits itself -- it polls the authoritative
        // balance and only accepts once the server-reported balance has
        // actually increased.
        expect(serviceSource, contains('_balance()'));
        expect(serviceSource, contains('balance > _baselineBalance'));
        expect(serviceSource, contains('_accept(balance)'));
      },
    );

    test(
      'rewarded-ad claim issuance is authenticated and fails closed without a configured secret',
      () {
        final backendClaimSource = File(
          'backend/src/ads/rewarded-identity-claim.ts',
        ).readAsStringSync();
        expect(backendClaimSource, contains('get configured(): boolean'));
        expect(
          backendClaimSource,
          contains("throw new Error('reward_claim_unconfigured')"),
        );
      },
    );

    test(
      'gem credit for a rewarded ad only happens after independent AdMob SSV + claim signature verification',
      () {
        final backendRouteSource = File(
          'backend/src/routes/rewarded-ads.ts',
        ).readAsStringSync();
        expect(backendRouteSource, contains('verifier.verify(parsed)'));
        expect(backendRouteSource, contains('claims.verify(parsed.customData'));
        expect(backendRouteSource, contains('ledger.credit('));
      },
    );
  });
}
