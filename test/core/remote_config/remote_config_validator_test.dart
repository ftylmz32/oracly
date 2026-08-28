import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/remote_config/remote_config_defaults.dart';
import 'package:oracly_new/core/remote_config/remote_config_validation.dart';
import 'package:oracly_new/core/remote_config/remote_config_validator.dart';

void main() {
  group('RemoteConfigValidator', () {
    test('missing payload falls back to local defaults', () {
      final result = RemoteConfigValidator.validate(null);
      expect(result.kind, RemoteConfigValidationKind.missing);
      expect(result.snapshot, RemoteConfigDefaults.snapshot);
    });

    test('invalid fields fall back; unsafe copy is rejected', () {
      final parsed = RemoteConfigValidator.parse({
        'config_version': 'not-a-number',
        'api_secret_key': 'sk-live-danger',
        'feature_flags': {
          'daily_ritual': 'yes',
          'premium_offers': false,
        },
        'gem_history_display_limit': 99,
        'copy_overrides': {
          'gems_note': 'Safe short copy.',
          'bad': 'Contact us at user@secret.com',
        },
      });
      expect(parsed.configVersion, RemoteConfigDefaults.snapshot.configVersion);
      expect(parsed.featureFlags['premium_offers'], false);
      expect(
        parsed.gemHistoryDisplayLimit,
        RemoteConfigDefaults.snapshot.gemHistoryDisplayLimit,
      );
      expect(parsed.copyOverrides.containsKey('gems_note'), isTrue);
      expect(parsed.copyOverrides.containsKey('bad'), isFalse);
    });

    test('rejects payload with only blocked keys', () {
      final result = RemoteConfigValidator.validate({
        'api_secret_key': 'sk-live',
        'billing_token': 'tok',
      });
      expect(result.kind, RemoteConfigValidationKind.rejected);
      expect(result.snapshot, RemoteConfigDefaults.snapshot);
    });

    test('unsupported min version rejects entire remote package', () {
      final result = RemoteConfigValidator.validate({
        'min_app_version': '9.0.0',
        'feature_flags': {'daily_ritual': false},
      });
      expect(result.kind, RemoteConfigValidationKind.unsupported);
      expect(result.snapshot, RemoteConfigDefaults.snapshot);
      expect(result.snapshot.featureFlags['daily_ritual'], isTrue);
    });

    test('merges valid remote values', () {
      final result = RemoteConfigValidator.validate({
        'config_version': 2,
        'feature_flags': {'daily_ritual': false},
        'gem_history_display_limit': 6,
        'notification_daily_hour': 11,
        'experiments': {'coffee_cta_copy': 'live'},
      });
      expect(result.kind, RemoteConfigValidationKind.accepted);
      expect(result.snapshot.configVersion, 2);
      expect(result.snapshot.featureFlags['daily_ritual'], false);
      expect(result.snapshot.gemHistoryDisplayLimit, 6);
      expect(result.snapshot.notificationDailyHour, 11);
      expect(result.snapshot.experiment('coffee_cta_copy'), 'live');
    });
  });
}
