/// Provider-id → AccountReauthMethod mapping.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/models/account_reauth_method.dart';

void main() {
  test('maps google.com / apple.com / password', () {
    expect(
      AccountReauthMethodResolver.fromProviderIds(const [
        'google.com',
        'apple.com',
        'password',
      ]),
      [
        AccountReauthMethod.google,
        AccountReauthMethod.apple,
        AccountReauthMethod.email,
      ],
    );
  });

  test('ignores anonymous and unknown providers', () {
    expect(
      AccountReauthMethodResolver.fromProviderIds(const [
        'firebase',
        'anonymous',
        'phone',
      ]),
      isEmpty,
    );
  });

  test('preferred order is Google → Apple → email', () {
    expect(
      AccountReauthMethodResolver.preferred(const [
        AccountReauthMethod.email,
        AccountReauthMethod.apple,
        AccountReauthMethod.google,
      ]),
      AccountReauthMethod.google,
    );
    expect(
      AccountReauthMethodResolver.preferred(const [
        AccountReauthMethod.email,
        AccountReauthMethod.apple,
      ]),
      AccountReauthMethod.apple,
    );
    expect(
      AccountReauthMethodResolver.preferred(const [AccountReauthMethod.email]),
      AccountReauthMethod.email,
    );
  });
}
