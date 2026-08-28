import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/remote_config/remote_config_security.dart';

void main() {
  group('RemoteConfigSecurity', () {
    test('allows only safe root keys', () {
      expect(RemoteConfigSecurity.isAllowedRootKey('feature_flags'), isTrue);
      expect(RemoteConfigSecurity.isAllowedRootKey('api_secret_key'), isFalse);
      expect(RemoteConfigSecurity.isAllowedRootKey('billing_token'), isFalse);
    });

    test('rejects unsafe copy', () {
      expect(RemoteConfigSecurity.isSafeCopy('Calm reflection note.'), isTrue);
      expect(RemoteConfigSecurity.isSafeCopy('Email us at help@test.com'), isFalse);
      expect(RemoteConfigSecurity.isSafeCopy('x' * 161), isFalse);
    });
  });
}
